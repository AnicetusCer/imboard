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
#include <limits>
#include <utility>

namespace
{
bool hasUnsupportedTextControl(const QList<uint> &codepoints)
{
    return std::any_of(codepoints.cbegin(), codepoints.cend(), [](uint codepoint) {
        return codepoint < 0x20 && codepoint != '\n'
               && codepoint != '\r' && codepoint != '\t';
    });
}

bool requiresUnicodePaste(const QList<uint> &codepoints)
{
    return std::any_of(codepoints.cbegin(), codepoints.cend(), [](uint codepoint) {
        return codepoint > 0x7e;
    });
}
}

InputController::InputController(QObject *parent)
    : QObject(parent), m_portal(this)
{
    const QSettings settings;
    m_experimentalUnicodeEnabled =
        settings.value(QStringLiteral("input/experimentalUnicode"), false).toBool();
    m_inputDiagnosticsEnabled =
        settings.value(QStringLiteral("input/diagnosticsEnabled"), false).toBool();
    if (settings.status() != QSettings::NoError)
        qWarning() << "Could not read input settings";

    connect(&m_portal, &PortalInputBackend::stateChanged,
            this, &InputController::backendReadyChanged);
    connect(&m_portal, &PortalInputBackend::inputEventCompleted,
            this, &InputController::recordPortalEvent);
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

bool InputController::localTextEditing() const noexcept
{
    return m_localTextEditing;
}

void InputController::setLocalTextEditing(bool enabled)
{
    if (m_localTextEditing == enabled) return;
    m_localTextEditing = enabled;
    emit localTextEditingChanged();
}

bool InputController::inputDiagnosticsEnabled() const noexcept
{
    return m_inputDiagnosticsEnabled;
}

void InputController::setInputDiagnosticsEnabled(bool enabled)
{
    if (m_inputDiagnosticsEnabled == enabled) return;

    QSettings settings;
    settings.setValue(QStringLiteral("input/diagnosticsEnabled"), enabled);
    settings.sync();
    if (settings.status() != QSettings::NoError) {
        qWarning() << "Could not save input diagnostics setting";
        return;
    }

    m_inputDiagnosticsEnabled = enabled;
    emit inputDiagnosticsEnabledChanged();
}

qulonglong InputController::diagnosticTouchStarts() const noexcept
{
    return m_diagnosticTouchStarts;
}

qulonglong InputController::diagnosticTouchActivations() const noexcept
{
    return m_diagnosticTouchActivations;
}

qulonglong InputController::diagnosticTouchCancellations() const noexcept
{
    return m_diagnosticTouchCancellations;
}

qulonglong InputController::diagnosticActionsRequested() const noexcept
{
    return m_diagnosticActionsRequested;
}

qulonglong InputController::diagnosticActionsCompleted() const noexcept
{
    return m_diagnosticActionsCompleted;
}

qulonglong InputController::diagnosticActionsFailed() const noexcept
{
    return m_diagnosticActionsFailed;
}

qulonglong InputController::diagnosticPortalEventsAccepted() const noexcept
{
    return m_diagnosticPortalEventsAccepted;
}

qulonglong InputController::diagnosticPortalEventsFailed() const noexcept
{
    return m_diagnosticPortalEventsFailed;
}

int InputController::diagnosticLastPortalLatencyMs() const noexcept
{
    return m_diagnosticLastPortalLatencyMs;
}

double InputController::diagnosticAveragePortalLatencyMs() const noexcept
{
    const qulonglong eventCount = m_diagnosticPortalEventsAccepted
                                 + m_diagnosticPortalEventsFailed;
    return eventCount == 0 ? 0.0
                           : static_cast<double>(m_diagnosticPortalLatencyTotalMs)
                                 / static_cast<double>(eventCount);
}

int InputController::diagnosticWorstPortalLatencyMs() const noexcept
{
    return m_diagnosticWorstPortalLatencyMs;
}

QString InputController::diagnosticSummary() const
{
    return QStringLiteral("DIAG T %1/%2/%3  A %4/%5  P %6/%7  L %8/%9 ms")
        .arg(m_diagnosticTouchStarts)
        .arg(m_diagnosticTouchActivations)
        .arg(m_diagnosticTouchCancellations)
        .arg(m_diagnosticActionsCompleted)
        .arg(m_diagnosticActionsFailed)
        .arg(m_diagnosticPortalEventsAccepted)
        .arg(m_diagnosticPortalEventsFailed)
        .arg(m_diagnosticLastPortalLatencyMs)
        .arg(m_diagnosticWorstPortalLatencyMs);
}

void InputController::recordDiagnosticTouchStarted()
{
    if (!m_inputDiagnosticsEnabled) return;
    ++m_diagnosticTouchStarts;
    emit inputDiagnosticsChanged();
}

void InputController::recordDiagnosticTouchActivated()
{
    if (!m_inputDiagnosticsEnabled) return;
    ++m_diagnosticTouchActivations;
    emit inputDiagnosticsChanged();
}

void InputController::recordDiagnosticTouchCanceled()
{
    if (!m_inputDiagnosticsEnabled) return;
    ++m_diagnosticTouchCancellations;
    emit inputDiagnosticsChanged();
}

void InputController::resetInputDiagnostics()
{
    m_diagnosticTouchStarts = 0;
    m_diagnosticTouchActivations = 0;
    m_diagnosticTouchCancellations = 0;
    m_diagnosticActionsRequested = 0;
    m_diagnosticActionsCompleted = 0;
    m_diagnosticActionsFailed = 0;
    m_diagnosticPortalEventsAccepted = 0;
    m_diagnosticPortalEventsFailed = 0;
    m_diagnosticPortalLatencyTotalMs = 0;
    m_diagnosticLastPortalLatencyMs = 0;
    m_diagnosticWorstPortalLatencyMs = 0;
    emit inputDiagnosticsChanged();
}

void InputController::beginDiagnosticAction()
{
    if (!m_inputDiagnosticsEnabled) return;
    ++m_diagnosticActionsRequested;
    emit inputDiagnosticsChanged();
}

void InputController::completeDiagnosticAction(bool accepted)
{
    if (!m_inputDiagnosticsEnabled) return;
    if (accepted)
        ++m_diagnosticActionsCompleted;
    else
        ++m_diagnosticActionsFailed;
    emit inputDiagnosticsChanged();
}

void InputController::recordPortalEvent(bool accepted, qint64 elapsedMilliseconds)
{
    if (!m_inputDiagnosticsEnabled) return;
    const int latency = static_cast<int>(std::clamp<qint64>(
        elapsedMilliseconds, 0, std::numeric_limits<int>::max()));
    if (accepted)
        ++m_diagnosticPortalEventsAccepted;
    else
        ++m_diagnosticPortalEventsFailed;
    m_diagnosticPortalLatencyTotalMs += static_cast<qulonglong>(latency);
    m_diagnosticLastPortalLatencyMs = latency;
    m_diagnosticWorstPortalLatencyMs = std::max(m_diagnosticWorstPortalLatencyMs, latency);
    emit inputDiagnosticsChanged();
}

bool InputController::canSendText(const QString &text) const
{
    const QList<uint> codepoints = text.toUcs4();
    if (hasUnsupportedTextControl(codepoints)) return false;
    return !requiresUnicodePaste(codepoints) || m_experimentalUnicodeEnabled;
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

bool InputController::sendText(const QString &text)
{
    const QList<uint> codepoints = text.toUcs4();
    const QString description = QStringLiteral("text:%1-codepoint%2")
                                    .arg(codepoints.size())
                                    .arg(codepoints.size() == 1 ? QString() : QStringLiteral("s"));
    emit actionRequested(description);
    beginDiagnosticAction();
    if (hasUnsupportedTextControl(codepoints)) {
        qWarning() << "Rejected text containing an unsupported control character";
        completeDiagnosticAction(false);
        return false;
    }
    if (m_localTextEditing) {
        emit localTextRequested(text);
        completeDiagnosticAction(true);
        return true;
    }
    const bool needsClipboardPaste = requiresUnicodePaste(codepoints);
    if (!backendReady()) {
        completeDiagnosticAction(false);
        return false;
    }
    if (needsClipboardPaste) {
        if (m_experimentalUnicodeEnabled) {
            const bool accepted = pasteTextViaClipboard(text);
            completeDiagnosticAction(accepted);
            return accepted;
        }
        qWarning() << "Rejected non-ASCII text because experimental Unicode input is disabled";
        completeDiagnosticAction(false);
        return false;
    }
    for (qsizetype index = 0; index < codepoints.size(); ++index) {
        const uint codepoint = codepoints.at(index);
        if (codepoint == '\r' && index + 1 < codepoints.size()
            && codepoints.at(index + 1) == '\n') {
            continue;
        }
        const quint32 keysym = codepoint == '\n' || codepoint == '\r' ? namedKeysym(QStringLiteral("Enter"))
                               : codepoint == '\t' ? namedKeysym(QStringLiteral("Tab"))
                                                    : codepoint;
        if (!m_portal.tapKeysym(keysym)) {
            completeDiagnosticAction(false);
            return false;
        }
    }
    completeDiagnosticAction(true);
    return true;
}

bool InputController::sendKey(const QString &key)
{
    const QString description = QStringLiteral("key:%1").arg(key);
    emit actionRequested(description);
    beginDiagnosticAction();
    const quint32 keysym = namedKeysym(key);
    if (keysym == 0) {
        qWarning().noquote() << "Unsupported key:" << key;
        completeDiagnosticAction(false);
        return false;
    }
    if (m_localTextEditing) {
        emit localKeyRequested(key);
        completeDiagnosticAction(true);
        return true;
    }
    const bool accepted = backendReady() && m_portal.tapKeysym(keysym);
    completeDiagnosticAction(accepted);
    return accepted;
}

bool InputController::sendChord(const QStringList &modifiers, const QString &key)
{
    const QString description = QStringLiteral("chord:%1+%2")
                                    .arg(modifiers.join(QLatin1Char('+')), key);
    emit actionRequested(description);
    beginDiagnosticAction();
    const QSet<QString> allowedModifiers{
        QStringLiteral("Ctrl"), QStringLiteral("Shift"),
        QStringLiteral("Alt"), QStringLiteral("Meta")};
    if (modifiers.isEmpty()) {
        qWarning() << "Rejected a chord without modifiers";
        completeDiagnosticAction(false);
        return false;
    }
    QList<quint32> modifierKeysyms;
    for (const QString &modifier : modifiers) {
        const quint32 keysym = namedKeysym(modifier);
        if (!allowedModifiers.contains(modifier)
            || keysym == 0 || modifierKeysyms.contains(keysym)) {
            qWarning().noquote() << "Invalid chord modifier:" << modifier;
            completeDiagnosticAction(false);
            return false;
        }
        modifierKeysyms.append(keysym);
    }
    const QString normalizedKey = normalizedChordKey(modifiers, key);
    const quint32 keysym = namedKeysym(normalizedKey);
    if (keysym == 0) {
        qWarning().noquote() << "Unsupported chord key:" << key;
        completeDiagnosticAction(false);
        return false;
    }
    if (m_localTextEditing) {
        emit localChordRequested(modifiers, key);
        completeDiagnosticAction(true);
        return true;
    }
    if (!backendReady()) {
        completeDiagnosticAction(false);
        return false;
    }

    QList<quint32> pressedModifiers;
    for (const quint32 modifierKeysym : std::as_const(modifierKeysyms)) {
        if (!m_portal.pressKeysym(modifierKeysym)) break;
        pressedModifiers.append(modifierKeysym);
    }
    bool accepted = pressedModifiers.size() == modifierKeysyms.size();
    if (accepted) accepted = m_portal.tapKeysym(keysym);
    for (auto iterator = pressedModifiers.crbegin(); iterator != pressedModifiers.crend(); ++iterator) {
        if (!m_portal.releaseKeysym(*iterator)) accepted = false;
    }
    completeDiagnosticAction(accepted);
    return accepted;
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
