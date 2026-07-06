// SPDX-FileCopyrightText: 2026 AnicetusCer
// SPDX-License-Identifier: GPL-3.0-or-later

#pragma once

#include <QObject>
#include <QTimer>
#include <QVariantMap>

class StartupManager final : public QObject
{
    Q_OBJECT
    Q_PROPERTY(bool enabled READ enabled NOTIFY enabledChanged)
    Q_PROPERTY(bool busy READ busy NOTIFY busyChanged)
    Q_PROPERTY(bool promptRequired READ promptRequired NOTIFY promptRequiredChanged)
    Q_PROPERTY(QString error READ error NOTIFY errorChanged)

public:
    explicit StartupManager(QObject *parent = nullptr);
    ~StartupManager() override;

    [[nodiscard]] bool enabled() const;
    [[nodiscard]] bool busy() const noexcept;
    [[nodiscard]] bool promptRequired() const;
    [[nodiscard]] QString error() const;
    Q_INVOKABLE bool setEnabled(bool enabled);
    Q_INVOKABLE bool acceptStartupPrompt();
    Q_INVOKABLE void declineStartupPrompt();

signals:
    void enabledChanged();
    void busyChanged();
    void promptRequiredChanged();
    void errorChanged();

private slots:
    void handlePortalResponse(uint response, const QVariantMap &results);

private:
    static QString autostartPath();
    static bool isFlatpak();
    bool requestPortalAutostart(bool enabled);
    void cancelPortalRequest();
    bool startupPromptSeen() const;
    void setStartupPromptSeen(bool seen);
    void setError(const QString &error);

    bool m_busy = false;
    bool m_requestedEnabled = false;
    QString m_requestPath;
    QString m_error;
    QTimer m_requestTimer;
};
