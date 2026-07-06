// SPDX-FileCopyrightText: 2026 AnicetusCer
// SPDX-License-Identifier: GPL-3.0-or-later

#include "inputcontroller.h"

#include <QDebug>
#include <QGuiApplication>
#include <QHash>
#include <QClipboard>
#include <QSet>
#include <QSettings>
#include <QTimer>

#include <algorithm>
#include <utility>

InputController::InputController(QObject *parent)
    : QObject(parent), m_portal(this)
{
    const QSettings settings;
    m_experimentalUnicodeEnabled =
        settings.value(QStringLiteral("input/experimentalUnicode"), false).toBool();
    if (settings.status() != QSettings::NoError)
        qWarning() << "Could not read experimental Unicode input setting";

    connect(&m_portal, &PortalInputBackend::stateChanged,
            this, &InputController::backendReadyChanged);
}

bool InputController::backendReady() const noexcept
{
    return m_portal.ready();
}

QString InputController::backendStatus() const
{
    return m_portal.status();
}

bool InputController::setupRequired() const
{
    return !m_portal.setupComplete();
}

bool InputController::experimentalUnicodeEnabled() const noexcept
{
    return m_experimentalUnicodeEnabled;
}

void InputController::setExperimentalUnicodeEnabled(bool enabled)
{
    if (m_experimentalUnicodeEnabled == enabled) return;

    QSettings settings;
    settings.setValue(QStringLiteral("input/experimentalUnicode"), enabled);
    settings.sync();
    if (settings.status() != QSettings::NoError) {
        qWarning() << "Could not save experimental Unicode input setting";
        return;
    }

    m_experimentalUnicodeEnabled = enabled;
    emit experimentalUnicodeEnabledChanged();
}

void InputController::connectPortal()
{
    m_portal.connectPortal();
}

void InputController::disconnectPortal()
{
    m_portal.disconnectPortal();
}

void InputController::restorePortalIfConfigured()
{
    m_portal.restoreIfConfigured();
}

bool InputController::forgetPortalPermission()
{
    return m_portal.forgetPermission();
}

void InputController::sendText(const QString &text)
{
    const QList<uint> codepoints = text.toUcs4();
    const QString description = QStringLiteral("text:%1-codepoint%2")
                                    .arg(codepoints.size())
                                    .arg(codepoints.size() == 1 ? QString() : QStringLiteral("s"));
    qInfo().noquote() << description;
    emit actionRequested(description);
    if (!backendReady()) return;
    const bool needsClipboardPaste = std::any_of(codepoints.cbegin(), codepoints.cend(), [](uint codepoint) {
        return codepoint < 0x20 || codepoint > 0x7e;
    });
    if (needsClipboardPaste) {
        if (m_experimentalUnicodeEnabled) pasteTextViaClipboard(text);
        else qWarning() << "Rejected non-ASCII text because experimental Unicode input is disabled";
        return;
    }
    for (uint codepoint : codepoints) {
        const quint32 keysym = codepoint;
        if (!m_portal.tapKeysym(keysym)) break;
    }
}

void InputController::sendKey(const QString &key)
{
    const QString description = QStringLiteral("key:%1").arg(key);
    qInfo().noquote() << description;
    emit actionRequested(description);
    const quint32 keysym = namedKeysym(key);
    if (keysym == 0) {
        qWarning().noquote() << "Unsupported key:" << key;
        return;
    }
    if (backendReady()) m_portal.tapKeysym(keysym);
}

void InputController::sendChord(const QStringList &modifiers, const QString &key)
{
    const QString description = QStringLiteral("chord:%1+%2")
                                    .arg(modifiers.join(QLatin1Char('+')), key);
    qInfo().noquote() << description;
    emit actionRequested(description);
    const QSet<QString> allowedModifiers{
        QStringLiteral("Ctrl"), QStringLiteral("Shift"),
        QStringLiteral("Alt"), QStringLiteral("Meta")};
    if (modifiers.isEmpty()) {
        qWarning() << "Rejected a chord without modifiers";
        return;
    }
    QList<quint32> modifierKeysyms;
    for (const QString &modifier : modifiers) {
        const quint32 keysym = namedKeysym(modifier);
        if (!allowedModifiers.contains(modifier)
            || keysym == 0 || modifierKeysyms.contains(keysym)) {
            qWarning().noquote() << "Invalid chord modifier:" << modifier;
            return;
        }
        modifierKeysyms.append(keysym);
    }
    const QString normalizedKey = normalizedChordKey(modifiers, key);
    const quint32 keysym = namedKeysym(normalizedKey);
    if (keysym == 0) {
        qWarning().noquote() << "Unsupported chord key:" << key;
        return;
    }
    if (!backendReady()) return;

    QList<quint32> pressedModifiers;
    for (const quint32 modifierKeysym : std::as_const(modifierKeysyms)) {
        if (!m_portal.pressKeysym(modifierKeysym)) break;
        pressedModifiers.append(modifierKeysym);
    }
    if (pressedModifiers.size() == modifierKeysyms.size())
        m_portal.tapKeysym(keysym);
    for (auto iterator = pressedModifiers.crbegin(); iterator != pressedModifiers.crend(); ++iterator) {
        m_portal.releaseKeysym(*iterator);
    }
}

bool InputController::pasteTextViaClipboard(const QString &text)
{
    auto *clipboard = QGuiApplication::clipboard();
    if (!clipboard || !backendReady()) return false;
    const QString previousText = clipboard->text(QClipboard::Clipboard);
    clipboard->setText(text, QClipboard::Clipboard);
    QTimer::singleShot(100, this, [this]() {
        sendChord({QStringLiteral("Ctrl")}, QStringLiteral("V"));
    });
    QTimer::singleShot(1000, this, [text, previousText]() {
        auto *clipboard = QGuiApplication::clipboard();
        if (clipboard && clipboard->text(QClipboard::Clipboard) == text)
            clipboard->setText(previousText, QClipboard::Clipboard);
    });
    return true;
}

quint32 InputController::namedKeysym(const QString &key)
{
    static const QHash<QString, quint32> values{
        {QStringLiteral("Escape"), 0xff1b}, {QStringLiteral("Tab"), 0xff09},
        {QStringLiteral("Backspace"), 0xff08}, {QStringLiteral("Enter"), 0xff0d},
        {QStringLiteral("Left"), 0xff51}, {QStringLiteral("Up"), 0xff52},
        {QStringLiteral("Right"), 0xff53}, {QStringLiteral("Down"), 0xff54},
        {QStringLiteral("Home"), 0xff50}, {QStringLiteral("End"), 0xff57},
        {QStringLiteral("PageUp"), 0xff55}, {QStringLiteral("PageDown"), 0xff56},
        {QStringLiteral("Insert"), 0xff63}, {QStringLiteral("Delete"), 0xffff},
        {QStringLiteral("CapsLock"), 0xffe5}, {QStringLiteral("NumLock"), 0xff7f},
        {QStringLiteral("ScrollLock"), 0xff14}, {QStringLiteral("PrintScreen"), 0xff61},
        {QStringLiteral("Pause"), 0xff13}, {QStringLiteral("Menu"), 0xff67},
        {QStringLiteral("Space"), 0x20}, {QStringLiteral("Ctrl"), 0xffe3},
        {QStringLiteral("Shift"), 0xffe1}, {QStringLiteral("Alt"), 0xffe9},
        {QStringLiteral("Meta"), 0xffe7},
    };
    if (values.contains(key)) return values.value(key);
    if (key.size() == 1) return key.at(0).unicode();
    if (key.startsWith(QLatin1Char('F'))) {
        bool ok = false;
        const int number = key.mid(1).toInt(&ok);
        if (ok && number >= 1 && number <= 12) return 0xffbd + number;
    }
    return 0;
}

QString InputController::normalizedChordKey(const QStringList &modifiers, const QString &key)
{
    if (key.size() == 1 && key.at(0).isLetter()
        && !modifiers.contains(QStringLiteral("Shift"))) {
        return key.toLower();
    }
    return key;
}
