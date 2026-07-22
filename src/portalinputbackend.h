// SPDX-FileCopyrightText: 2026 AnicetusCer
// SPDX-License-Identifier: GPL-3.0-or-later

#pragma once

#include <QObject>
#include <QString>
#include <QTimer>
#include <QVariantMap>

class PortalInputBackend final : public QObject
{
    Q_OBJECT

public:
    explicit PortalInputBackend(QObject *parent = nullptr);
    ~PortalInputBackend() override;

    [[nodiscard]] bool ready() const noexcept;
    [[nodiscard]] QString status() const;
    [[nodiscard]] bool setupComplete() const;

    void connectPortal();
    void restoreIfConfigured();
    void disconnectPortal();
    bool forgetPermission();
    bool pressKeysym(quint32 keysym);
    bool releaseKeysym(quint32 keysym);
    bool tapKeysym(quint32 keysym);

signals:
    void stateChanged();

private slots:
    void handleResponse(uint response, const QVariantMap &results);
    void handlePortalServiceRegistered();
    void handlePortalServiceUnregistered();

private:
    enum class Stage { Idle, Waiting, Creating, Selecting, Starting, Ready, Error };
    bool beginRequest(const QString &method, const QVariantList &arguments, Stage stage);
    bool sendKeysym(quint32 keysym, bool pressed);
    bool portalServiceAvailable() const;
    void beginConnection();
    void scheduleReconnect();
    void waitForPortalService();
    void abandonPortalHandles();
    void closePortalHandles();
    void setError(const QString &message);
    static QString token();

    Stage m_stage = Stage::Idle;
    QString m_status = QStringLiteral("Disconnected");
    QString m_requestPath;
    QString m_sessionPath;
    QTimer m_requestTimer;
    QTimer m_reconnectTimer;
    bool m_connectionWanted = false;
};
