// SPDX-FileCopyrightText: 2026 AnicetusCer
// SPDX-License-Identifier: GPL-3.0-or-later

#include "appmetadata.h"
#include "startupmanager.h"

#include <QCoreApplication>
#include <QDBusConnection>
#include <QDBusInterface>
#include <QDBusMessage>
#include <QDBusObjectPath>
#include <QDBusPendingCall>
#include <QDebug>
#include <QDir>
#include <QFile>
#include <QFileInfo>
#include <QSaveFile>
#include <QSettings>
#include <QStandardPaths>
#include <QUuid>

namespace
{
constexpr auto PortalService = "org.freedesktop.portal.Desktop";
constexpr auto PortalPath = "/org/freedesktop/portal/desktop";
constexpr auto BackgroundInterface = "org.freedesktop.portal.Background";
constexpr auto RequestInterface = "org.freedesktop.portal.Request";

void closePortalRequest(const QString &path)
{
    QDBusMessage close = QDBusMessage::createMethodCall(
        PortalService, path, RequestInterface, QStringLiteral("Close"));
    const QDBusPendingCall pending = QDBusConnection::sessionBus().asyncCall(close);
    if (pending.isError())
        qWarning().noquote() << "Could not close startup portal request:"
                             << pending.error().message();
}
}

StartupManager::StartupManager(QObject *parent)
    : QObject(parent)
{
    m_requestTimer.setSingleShot(true);
    m_requestTimer.setInterval(120000);
    connect(&m_requestTimer, &QTimer::timeout, this, [this]() {
        cancelPortalRequest();
        m_busy = false;
        emit busyChanged();
        setError(QStringLiteral("The login startup request timed out"));
    });
}

StartupManager::~StartupManager()
{
    cancelPortalRequest();
}

bool StartupManager::enabled() const
{
    if (isFlatpak()) {
        const QSettings settings;
        const bool portalEnabled =
            settings.value(QStringLiteral("startup/portalEnabled"), false).toBool();
        if (settings.status() != QSettings::NoError)
            qWarning() << "Could not read saved login startup state";
        return portalEnabled;
    }
    return QFile::exists(autostartPath());
}

bool StartupManager::busy() const noexcept
{
    return m_busy;
}

bool StartupManager::promptRequired() const
{
    return !enabled() && !startupPromptSeen();
}

QString StartupManager::error() const
{
    return m_error;
}

bool StartupManager::setEnabled(bool enable)
{
    if (isFlatpak()) return requestPortalAutostart(enable);

    const bool wasEnabled = enabled();
    if (!enable) {
        if (wasEnabled && !QFile::remove(autostartPath())) {
            setError(QStringLiteral("Could not remove the Imboard autostart entry"));
            return false;
        }
        setError({});
        if (wasEnabled) emit enabledChanged();
        return true;
    }

    const QFileInfo executable(QCoreApplication::applicationFilePath());
    if (!executable.exists() || !executable.isExecutable()) {
        setError(QStringLiteral("Imboard executable path is unavailable"));
        return false;
    }
    const QFileInfo target(autostartPath());
    if (!QDir().mkpath(target.absolutePath())) {
        setError(QStringLiteral("Could not create the autostart directory"));
        return false;
    }

    QString escapedPath = executable.absoluteFilePath();
    escapedPath.replace(QLatin1Char('\\'), QStringLiteral("\\\\"));
    escapedPath.replace(QLatin1Char('"'), QStringLiteral("\\\""));
    const QByteArray desktopEntry = QStringLiteral(
        "[Desktop Entry]\n"
        "Type=Application\n"
        "Name=Imboard\n"
        "Comment=Start Imboard hidden for tray toggling\n"
        "Exec=\"%1\" --start-hidden\n"
        "Icon=%2\n"
        "X-GNOME-Autostart-enabled=true\n"
        "X-Imboard-Managed=true\n")
        .arg(escapedPath, QString::fromUtf8(Imboard::AppId)).toUtf8();

    QSaveFile file(autostartPath());
    if (!file.open(QIODevice::WriteOnly)) {
        setError(QStringLiteral("Could not open the Imboard autostart entry: %1")
                     .arg(file.errorString()));
        return false;
    }
    if (file.write(desktopEntry) != desktopEntry.size()) {
        setError(QStringLiteral("Could not write the Imboard autostart entry: %1")
                     .arg(file.errorString()));
        file.cancelWriting();
        return false;
    }
    if (!file.commit()) {
        setError(QStringLiteral("Could not save the Imboard autostart entry: %1")
                     .arg(file.errorString()));
        return false;
    }
    setError({});
    if (!wasEnabled) emit enabledChanged();
    return true;
}

bool StartupManager::acceptStartupPrompt()
{
    setStartupPromptSeen(true);
    return setEnabled(true);
}

void StartupManager::declineStartupPrompt()
{
    setStartupPromptSeen(true);
    setError({});
}

void StartupManager::handlePortalResponse(uint response, const QVariantMap &results)
{
    m_requestTimer.stop();
    if (!QDBusConnection::sessionBus().disconnect(
            PortalService, m_requestPath, RequestInterface, QStringLiteral("Response"),
            this, SLOT(handlePortalResponse(uint,QVariantMap)))) {
        qWarning() << "Could not detach from the completed startup portal request";
    }
    m_requestPath.clear();
    m_busy = false;
    emit busyChanged();

    if (response != 0) {
        setError(response == 1 ? QStringLiteral("Login startup request was cancelled")
                               : QStringLiteral("Login startup request failed"));
        return;
    }

    const bool portalEnabled = results.value(QStringLiteral("autostart"), false).toBool();
    const bool wasEnabled = enabled();
    QSettings settings;
    settings.setValue(QStringLiteral("startup/portalEnabled"), portalEnabled);
    settings.sync();
    if (settings.status() != QSettings::NoError) {
        setError(QStringLiteral("Login startup changed, but its state could not be saved"));
        return;
    }
    if (portalEnabled != m_requestedEnabled) {
        setError(m_requestedEnabled
                     ? QStringLiteral("Login startup was not allowed")
                     : QStringLiteral("Login startup could not be disabled"));
    } else {
        setError({});
    }
    if (wasEnabled != portalEnabled) emit enabledChanged();
    emit promptRequiredChanged();
}

QString StartupManager::autostartPath()
{
    return QStandardPaths::writableLocation(QStandardPaths::ConfigLocation)
           + QStringLiteral("/autostart/%1.desktop").arg(QString::fromUtf8(Imboard::AppId));
}

bool StartupManager::isFlatpak()
{
    return !qEnvironmentVariable("FLATPAK_ID").isEmpty();
}

bool StartupManager::requestPortalAutostart(bool enable)
{
    if (m_busy) return false;

    QString token = QUuid::createUuid().toString(QUuid::WithoutBraces);
    token.replace(QLatin1Char('-'), QLatin1Char('_'));
    token.prepend(QStringLiteral("imboard_startup_"));

    QVariantMap options{
        {QStringLiteral("handle_token"), token},
        {QStringLiteral("reason"),
         QStringLiteral("Start Imboard hidden so its tray icon can show the keyboard")},
        {QStringLiteral("autostart"), enable},
        {QStringLiteral("commandline"),
         QVariant::fromValue(QStringList{QStringLiteral("imboard"),
                                         QStringLiteral("--start-hidden")})},
    };

    m_busy = true;
    m_requestedEnabled = enable;
    setError({});
    emit busyChanged();

    QDBusInterface portal(PortalService, PortalPath, BackgroundInterface,
                          QDBusConnection::sessionBus());
    const QDBusMessage reply = portal.callWithArgumentList(
        QDBus::Block, QStringLiteral("RequestBackground"), {QString(), options});
    if (reply.type() == QDBusMessage::ErrorMessage || reply.arguments().isEmpty()) {
        m_busy = false;
        emit busyChanged();
        setError(reply.errorMessage().isEmpty()
                     ? QStringLiteral("Background portal is unavailable")
                     : reply.errorMessage());
        return false;
    }

    m_requestPath = reply.arguments().constFirst().value<QDBusObjectPath>().path();
    if (m_requestPath.isEmpty()
        || !QDBusConnection::sessionBus().connect(
            PortalService, m_requestPath, RequestInterface, QStringLiteral("Response"),
            this, SLOT(handlePortalResponse(uint,QVariantMap)))) {
        m_busy = false;
        cancelPortalRequest();
        emit busyChanged();
        setError(QStringLiteral("Could not monitor the login startup request"));
        return false;
    }
    m_requestTimer.start();
    return true;
}

void StartupManager::cancelPortalRequest()
{
    m_requestTimer.stop();
    if (m_requestPath.isEmpty()) return;
    if (!QDBusConnection::sessionBus().disconnect(
            PortalService, m_requestPath, RequestInterface, QStringLiteral("Response"),
            this, SLOT(handlePortalResponse(uint,QVariantMap)))) {
        qWarning() << "Could not detach from the startup portal request";
    }
    closePortalRequest(m_requestPath);
    m_requestPath.clear();
}

bool StartupManager::startupPromptSeen() const
{
    const QSettings settings;
    const bool seen = settings.value(QStringLiteral("startup/promptSeen"), false).toBool();
    if (settings.status() != QSettings::NoError)
        qWarning() << "Could not read saved startup prompt state";
    return seen;
}

void StartupManager::setStartupPromptSeen(bool seen)
{
    const bool wasRequired = promptRequired();
    QSettings settings;
    settings.setValue(QStringLiteral("startup/promptSeen"), seen);
    settings.sync();
    if (settings.status() != QSettings::NoError) {
        qWarning() << "Could not save startup prompt state";
        return;
    }
    if (wasRequired != promptRequired()) emit promptRequiredChanged();
}

void StartupManager::setError(const QString &error)
{
    if (m_error == error) return;
    m_error = error;
    emit errorChanged();
}
