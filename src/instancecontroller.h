// SPDX-FileCopyrightText: 2026 AnicetusCer
// SPDX-License-Identifier: GPL-3.0-or-later

#pragma once

#include <QObject>
#include <QString>

#include <memory>

class QLocalServer;
class QLockFile;

class InstanceController final : public QObject
{
    Q_OBJECT

public:
    explicit InstanceController(QObject *parent = nullptr);
    ~InstanceController() override;

    bool start();
    [[nodiscard]] QString error() const;
    static bool sendCommand(const QString &command, int timeoutMs = 1500);

signals:
    void showRequested();
    void toggleRequested();
    void quitRequested();

private:
    static QString lockPath();
    static QString socketPath();
    void acceptConnections();

    std::unique_ptr<QLockFile> m_lock;
    std::unique_ptr<QLocalServer> m_server;
    QString m_error;
};
