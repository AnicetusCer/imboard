// SPDX-FileCopyrightText: 2026 AnicetusCer
// SPDX-License-Identifier: GPL-3.0-or-later

#include "portalinputbackend.h"

#include <QDBusConnection>
#include <QDBusInterface>
#include <QDBusMessage>
#include <QDBusObjectPath>
#include <QDBusPendingCall>
#include <QSettings>
#include <QUuid>

namespace
{
constexpr auto Service = "org.freedesktop.portal.Desktop";
constexpr auto ObjectPath = "/org/freedesktop/portal/desktop";
constexpr auto Interface = "org.freedesktop.portal.RemoteDesktop";
constexpr auto RequestInterface = "org.freedesktop.portal.Request";

void closePortalObject(const QString &path, const QString &interface)
{
    QDBusMessage close = QDBusMessage::createMethodCall(
        Service, path, interface, QStringLiteral("Close"));
    const QDBusPendingCall pending = QDBusConnection::sessionBus().asyncCall(close);
    if (pending.isError())
        qWarning().noquote() << "Could not close portal object:" << pending.error().message();
}
}

PortalInputBackend::PortalInputBackend(QObject *parent)
    : QObject(parent)
{
    m_requestTimer.setSingleShot(true);
    m_requestTimer.setInterval(120000);
    connect(&m_requestTimer, &QTimer::timeout, this, [this]() {
        setError(QStringLiteral("The keyboard permission request timed out"));
    });
}

PortalInputBackend::~PortalInputBackend()
{
    disconnectPortal();
}

bool PortalInputBackend::ready() const noexcept
{
    return m_stage == Stage::Ready;
}

QString PortalInputBackend::status() const
{
    return m_status;
}

bool PortalInputBackend::setupComplete() const
{
    const QSettings settings;
    const bool complete = settings.value(QStringLiteral("portal/setupComplete"), false).toBool()
                          && !settings.value(QStringLiteral("portal/restoreToken"))
                                  .toString().isEmpty();
    if (settings.status() != QSettings::NoError)
        qWarning() << "Could not read saved keyboard permission state";
    return complete;
}

void PortalInputBackend::connectPortal()
{
    if (m_stage != Stage::Idle && m_stage != Stage::Error) return;
    QVariantMap options{
        {QStringLiteral("handle_token"), token()},
        {QStringLiteral("session_handle_token"), token()},
    };
    m_status = QStringLiteral("Requesting session");
    emit stateChanged();
    beginRequest(QStringLiteral("CreateSession"), {options}, Stage::Creating);
}

void PortalInputBackend::restoreIfConfigured()
{
    if (setupComplete()) {
        connectPortal();
    }
}

void PortalInputBackend::disconnectPortal()
{
    closePortalHandles();
    const bool changed = m_stage != Stage::Idle;
    m_stage = Stage::Idle;
    m_status = QStringLiteral("Disconnected");
    if (changed) emit stateChanged();
}

void PortalInputBackend::closePortalHandles()
{
    m_requestTimer.stop();
    if (!m_requestPath.isEmpty()) {
        if (!QDBusConnection::sessionBus().disconnect(
                Service, m_requestPath, RequestInterface, QStringLiteral("Response"), this,
                SLOT(handleResponse(uint,QVariantMap)))) {
            qWarning() << "Could not detach from the active portal request";
        }
        closePortalObject(m_requestPath, QString::fromLatin1(RequestInterface));
        m_requestPath.clear();
    }
    if (!m_sessionPath.isEmpty()) {
        closePortalObject(m_sessionPath, QStringLiteral("org.freedesktop.portal.Session"));
        m_sessionPath.clear();
    }
}

bool PortalInputBackend::forgetPermission()
{
    disconnectPortal();
    QSettings settings;
    settings.remove(QStringLiteral("portal/restoreToken"));
    settings.remove(QStringLiteral("portal/setupComplete"));
    settings.sync();
    if (settings.status() != QSettings::NoError) {
        setError(QStringLiteral("Could not delete the saved keyboard permission"));
        return false;
    }
    m_status = QStringLiteral("Access removed");
    emit stateChanged();
    return true;
}

bool PortalInputBackend::sendKeysym(quint32 keysym, bool pressed)
{
    if (!ready()) return false;
    QDBusMessage message = QDBusMessage::createMethodCall(Service, ObjectPath, Interface,
                                                           QStringLiteral("NotifyKeyboardKeysym"));
    message << QVariant::fromValue(QDBusObjectPath(m_sessionPath)) << QVariantMap{}
            << qint32(keysym) << uint(pressed ? 1 : 0);
    const QDBusMessage reply = QDBusConnection::sessionBus().call(
        message, QDBus::Block, 1000);
    if (reply.type() != QDBusMessage::ErrorMessage) return true;
    qWarning().noquote() << "Keyboard portal event failed:" << reply.errorMessage();
    return false;
}

bool PortalInputBackend::tapKeysym(quint32 keysym)
{
    return pressKeysym(keysym) && releaseKeysym(keysym);
}

bool PortalInputBackend::pressKeysym(quint32 keysym)
{
    if (sendKeysym(keysym, true)) return true;
    setError(QStringLiteral("Keyboard input failed; access was disconnected"));
    return false;
}

bool PortalInputBackend::releaseKeysym(quint32 keysym)
{
    if (sendKeysym(keysym, false)) return true;

    // A missing release can leave the compositor repeating a key. Retry once;
    // if it still fails, closing the portal session releases all virtual keys.
    if (sendKeysym(keysym, false)) return true;
    setError(QStringLiteral("Keyboard release failed; access was disconnected"));
    return false;
}

void PortalInputBackend::handleResponse(uint response, const QVariantMap &results)
{
    m_requestTimer.stop();
    if (!QDBusConnection::sessionBus().disconnect(
            Service, m_requestPath, RequestInterface, QStringLiteral("Response"), this,
            SLOT(handleResponse(uint,QVariantMap)))) {
        qWarning() << "Could not detach from the completed portal request";
    }
    m_requestPath.clear();
    if (response != 0) {
        setError(response == 1 ? QStringLiteral("Permission cancelled")
                               : QStringLiteral("Portal request failed"));
        return;
    }

    if (m_stage == Stage::Creating) {
        const QVariant handle = results.value(QStringLiteral("session_handle"));
        m_sessionPath = handle.canConvert<QDBusObjectPath>()
                        ? handle.value<QDBusObjectPath>().path() : handle.toString();
        if (m_sessionPath.isEmpty()) {
            setError(QStringLiteral("Portal returned no session"));
            return;
        }
        QVariantMap options{
            {QStringLiteral("handle_token"), token()},
            {QStringLiteral("types"), uint(1)},
            {QStringLiteral("persist_mode"), uint(2)},
        };
        const QString restoreToken = QSettings().value(QStringLiteral("portal/restoreToken")).toString();
        if (!restoreToken.isEmpty()) options.insert(QStringLiteral("restore_token"), restoreToken);
        m_status = QStringLiteral("Requesting keyboard access");
        emit stateChanged();
        beginRequest(QStringLiteral("SelectDevices"),
                     {QVariant::fromValue(QDBusObjectPath(m_sessionPath)), options}, Stage::Selecting);
    } else if (m_stage == Stage::Selecting) {
        QVariantMap options{{QStringLiteral("handle_token"), token()}};
        m_status = QStringLiteral("Waiting for permission");
        emit stateChanged();
        beginRequest(QStringLiteral("Start"),
                     {QVariant::fromValue(QDBusObjectPath(m_sessionPath)), QString(), options}, Stage::Starting);
    } else if (m_stage == Stage::Starting) {
        const uint devices = results.value(QStringLiteral("devices"), uint(0)).toUInt();
        if ((devices & uint(1)) == 0) {
            setError(QStringLiteral("Keyboard access was not granted"));
            return;
        }
        const QString restoreToken = results.value(QStringLiteral("restore_token")).toString();
        if (restoreToken.isEmpty()) {
            setError(QStringLiteral("The portal did not provide reusable keyboard access"));
            return;
        }
        QSettings settings;
        settings.setValue(QStringLiteral("portal/restoreToken"), restoreToken);
        settings.setValue(QStringLiteral("portal/setupComplete"), true);
        settings.sync();
        if (settings.status() != QSettings::NoError) {
            setError(QStringLiteral("Could not save the keyboard permission"));
            return;
        }
        m_stage = Stage::Ready;
        m_status = QStringLiteral("Connected");
        emit stateChanged();
    }
}

bool PortalInputBackend::beginRequest(const QString &method, const QVariantList &arguments, Stage stage)
{
    QDBusInterface portal(Service, ObjectPath, Interface, QDBusConnection::sessionBus());
    QDBusMessage reply = portal.callWithArgumentList(QDBus::Block, method, arguments);
    if (reply.type() == QDBusMessage::ErrorMessage || reply.arguments().isEmpty()) {
        setError(reply.errorMessage().isEmpty() ? QStringLiteral("Portal is unavailable")
                                                : reply.errorMessage());
        return false;
    }
    m_requestPath = reply.arguments().constFirst().value<QDBusObjectPath>().path();
    if (m_requestPath.isEmpty()
        || !QDBusConnection::sessionBus().connect(Service, m_requestPath, RequestInterface,
                                                   QStringLiteral("Response"), this,
                                                   SLOT(handleResponse(uint,QVariantMap)))) {
        setError(QStringLiteral("Could not monitor portal request"));
        return false;
    }
    m_stage = stage;
    m_requestTimer.start();
    return true;
}

void PortalInputBackend::setError(const QString &message)
{
    closePortalHandles();
    m_stage = Stage::Error;
    m_status = message;
    emit stateChanged();
}

QString PortalInputBackend::token()
{
    QString value = QUuid::createUuid().toString(QUuid::WithoutBraces);
    value.replace(QLatin1Char('-'), QLatin1Char('_'));
    return QStringLiteral("imboard_%1").arg(value);
}
