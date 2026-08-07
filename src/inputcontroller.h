// SPDX-FileCopyrightText: 2026 AnicetusCer
// SPDX-License-Identifier: GPL-3.0-or-later

#pragma once

#include <QObject>
#include <QString>
#include <QStringList>

#include "portalinputbackend.h"

class InputController final : public QObject
{
    Q_OBJECT
    Q_PROPERTY(bool backendReady READ backendReady NOTIFY backendReadyChanged)
    Q_PROPERTY(QString backendStatus READ backendStatus NOTIFY backendReadyChanged)
    Q_PROPERTY(bool setupRequired READ setupRequired NOTIFY backendReadyChanged)
    Q_PROPERTY(bool experimentalUnicodeEnabled READ experimentalUnicodeEnabled
                   WRITE setExperimentalUnicodeEnabled
                   NOTIFY experimentalUnicodeEnabledChanged)
    Q_PROPERTY(bool localTextEditing READ localTextEditing WRITE setLocalTextEditing
                   NOTIFY localTextEditingChanged)
    Q_PROPERTY(bool inputDiagnosticsEnabled READ inputDiagnosticsEnabled
                   WRITE setInputDiagnosticsEnabled
                   NOTIFY inputDiagnosticsEnabledChanged)
    Q_PROPERTY(qulonglong diagnosticTouchStarts READ diagnosticTouchStarts
                   NOTIFY inputDiagnosticsChanged)
    Q_PROPERTY(qulonglong diagnosticTouchActivations READ diagnosticTouchActivations
                   NOTIFY inputDiagnosticsChanged)
    Q_PROPERTY(qulonglong diagnosticTouchCancellations READ diagnosticTouchCancellations
                   NOTIFY inputDiagnosticsChanged)
    Q_PROPERTY(qulonglong diagnosticActionsRequested READ diagnosticActionsRequested
                   NOTIFY inputDiagnosticsChanged)
    Q_PROPERTY(qulonglong diagnosticActionsCompleted READ diagnosticActionsCompleted
                   NOTIFY inputDiagnosticsChanged)
    Q_PROPERTY(qulonglong diagnosticActionsFailed READ diagnosticActionsFailed
                   NOTIFY inputDiagnosticsChanged)
    Q_PROPERTY(qulonglong diagnosticPortalEventsAccepted READ diagnosticPortalEventsAccepted
                   NOTIFY inputDiagnosticsChanged)
    Q_PROPERTY(qulonglong diagnosticPortalEventsFailed READ diagnosticPortalEventsFailed
                   NOTIFY inputDiagnosticsChanged)
    Q_PROPERTY(int diagnosticLastPortalLatencyMs READ diagnosticLastPortalLatencyMs
                   NOTIFY inputDiagnosticsChanged)
    Q_PROPERTY(double diagnosticAveragePortalLatencyMs READ diagnosticAveragePortalLatencyMs
                   NOTIFY inputDiagnosticsChanged)
    Q_PROPERTY(int diagnosticWorstPortalLatencyMs READ diagnosticWorstPortalLatencyMs
                   NOTIFY inputDiagnosticsChanged)
    Q_PROPERTY(QString diagnosticSummary READ diagnosticSummary
                   NOTIFY inputDiagnosticsChanged)

public:
    explicit InputController(QObject *parent = nullptr);

    [[nodiscard]] bool backendReady() const noexcept;
    [[nodiscard]] QString backendStatus() const;
    [[nodiscard]] bool setupRequired() const;
    [[nodiscard]] bool experimentalUnicodeEnabled() const noexcept;
    void setExperimentalUnicodeEnabled(bool enabled);
    [[nodiscard]] bool localTextEditing() const noexcept;
    void setLocalTextEditing(bool enabled);
    [[nodiscard]] bool inputDiagnosticsEnabled() const noexcept;
    void setInputDiagnosticsEnabled(bool enabled);
    [[nodiscard]] qulonglong diagnosticTouchStarts() const noexcept;
    [[nodiscard]] qulonglong diagnosticTouchActivations() const noexcept;
    [[nodiscard]] qulonglong diagnosticTouchCancellations() const noexcept;
    [[nodiscard]] qulonglong diagnosticActionsRequested() const noexcept;
    [[nodiscard]] qulonglong diagnosticActionsCompleted() const noexcept;
    [[nodiscard]] qulonglong diagnosticActionsFailed() const noexcept;
    [[nodiscard]] qulonglong diagnosticPortalEventsAccepted() const noexcept;
    [[nodiscard]] qulonglong diagnosticPortalEventsFailed() const noexcept;
    [[nodiscard]] int diagnosticLastPortalLatencyMs() const noexcept;
    [[nodiscard]] double diagnosticAveragePortalLatencyMs() const noexcept;
    [[nodiscard]] int diagnosticWorstPortalLatencyMs() const noexcept;
    [[nodiscard]] QString diagnosticSummary() const;
    Q_INVOKABLE bool canSendText(const QString &text) const;
    Q_INVOKABLE void recordDiagnosticTouchStarted();
    Q_INVOKABLE void recordDiagnosticTouchActivated();
    Q_INVOKABLE void recordDiagnosticTouchCanceled();
    Q_INVOKABLE void resetInputDiagnostics();

    Q_INVOKABLE void connectPortal();
    Q_INVOKABLE void disconnectPortal();
    Q_INVOKABLE void restorePortalIfConfigured();
    Q_INVOKABLE bool forgetPortalPermission();

    Q_INVOKABLE bool sendText(const QString &text);
    Q_INVOKABLE bool sendKey(const QString &key);
    Q_INVOKABLE bool sendChord(const QStringList &modifiers, const QString &key);

signals:
    void backendReadyChanged();
    void experimentalUnicodeEnabledChanged();
    void localTextEditingChanged();
    void inputDiagnosticsEnabledChanged();
    void inputDiagnosticsChanged();
    void localTextRequested(const QString &text);
    void localKeyRequested(const QString &key);
    void localChordRequested(const QStringList &modifiers, const QString &key);
    void actionRequested(const QString &description);

private:
    friend class InputControllerTest;

    void beginDiagnosticAction();
    void completeDiagnosticAction(bool accepted);
    void recordPortalEvent(bool accepted, qint64 elapsedMilliseconds);
    bool pasteTextViaClipboard(const QString &text);
    static quint32 namedKeysym(const QString &key);
    static QString normalizedChordKey(const QStringList &modifiers, const QString &key);
    PortalInputBackend m_portal;
    bool m_experimentalUnicodeEnabled = false;
    bool m_localTextEditing = false;
    bool m_inputDiagnosticsEnabled = false;
    qulonglong m_diagnosticTouchStarts = 0;
    qulonglong m_diagnosticTouchActivations = 0;
    qulonglong m_diagnosticTouchCancellations = 0;
    qulonglong m_diagnosticActionsRequested = 0;
    qulonglong m_diagnosticActionsCompleted = 0;
    qulonglong m_diagnosticActionsFailed = 0;
    qulonglong m_diagnosticPortalEventsAccepted = 0;
    qulonglong m_diagnosticPortalEventsFailed = 0;
    qulonglong m_diagnosticPortalLatencyTotalMs = 0;
    int m_diagnosticLastPortalLatencyMs = 0;
    int m_diagnosticWorstPortalLatencyMs = 0;
};
