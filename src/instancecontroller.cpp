// SPDX-FileCopyrightText: 2026 AnicetusCer
// SPDX-License-Identifier: GPL-3.0-or-later

#include "instancecontroller.h"

#include <QDebug>
#include <QDir>
#include <QFile>
#include <QLocalServer>
#include <QLocalSocket>
#include <QLockFile>
#include <QStandardPaths>

#include <unistd.h>

namespace
{
constexpr qsizetype MaximumCommandBytes = 32;

QString runtimePath(const QString &name)
{
    QString directory = QStandardPaths::writableLocation(QStandardPaths::RuntimeLocation);
    if (directory.isEmpty()) {
        directory = QDir::tempPath() + QStringLiteral("/imboard-%1").arg(getuid());
        if (!QDir().mkpath(directory)
            || !QFile::setPermissions(directory,
                                      QFileDevice::ReadOwner | QFileDevice::WriteOwner
                                          | QFileDevice::ExeOwner)) {
            return {};
        }
    }
    return directory + QLatin1Char('/') + name;
}
}

InstanceController::InstanceController(QObject *parent)
    : QObject(parent)
{
}

InstanceController::~InstanceController() = default;

bool InstanceController::start()
{
    m_error.clear();
    const QString lockFilePath = lockPath();
    const QString serverPath = socketPath();
    if (lockFilePath.isEmpty() || serverPath.isEmpty()) {
        m_error = QStringLiteral("Could not create a private runtime directory");
        return false;
    }

    m_lock = std::make_unique<QLockFile>(lockFilePath);
    m_lock->setStaleLockTime(0);
    if (!m_lock->tryLock(0)) {
        m_error = QStringLiteral("The Imboard instance lock is already held or unavailable");
        return false;
    }

    // removeServer() also returns false when there is simply no stale socket.
    // listen() below provides the actionable error if cleanup was required and failed.
    QLocalServer::removeServer(serverPath);
    m_server = std::make_unique<QLocalServer>();
    m_server->setSocketOptions(QLocalServer::UserAccessOption);
    if (!m_server->listen(serverPath)) {
        m_error = QStringLiteral("Could not open the local control socket: %1")
                      .arg(m_server->errorString());
        m_lock->unlock();
        return false;
    }
    connect(m_server.get(), &QLocalServer::newConnection,
            this, &InstanceController::acceptConnections);
    return true;
}

QString InstanceController::error() const
{
    return m_error;
}

bool InstanceController::sendCommand(const QString &command, int timeoutMs)
{
    QLocalSocket socket;
    socket.connectToServer(socketPath(), QIODevice::ReadWrite);
    if (!socket.waitForConnected(timeoutMs)) {
        return false;
    }
    const QByteArray payload = command.toUtf8() + '\n';
    if (socket.write(payload) != payload.size()
        || !socket.waitForBytesWritten(timeoutMs)) {
        return false;
    }
    if (!socket.waitForReadyRead(timeoutMs)) {
        return false;
    }
    return socket.readAll().startsWith("OK");
}

QString InstanceController::lockPath()
{
    return runtimePath(QStringLiteral("imboard-window.lock"));
}

QString InstanceController::socketPath()
{
    return runtimePath(QStringLiteral("imboard-window.sock"));
}

void InstanceController::acceptConnections()
{
    while (m_server && m_server->hasPendingConnections()) {
        QLocalSocket *socket = m_server->nextPendingConnection();
        if (!socket) {
            qWarning() << "The Imboard control socket lost a pending connection";
            continue;
        }
        connect(socket, &QLocalSocket::readyRead, socket, [this, socket]() {
            if (socket->bytesAvailable() > MaximumCommandBytes) {
                if (socket->write("ERROR\n") != 6 || !socket->flush())
                    qWarning() << "Could not reply on the Imboard control socket";
                socket->disconnectFromServer();
                return;
            }
            const QByteArray command = socket->readLine().trimmed().toUpper();
            const auto reply = [socket](const QByteArray &message) {
                if (socket->write(message) != message.size() || !socket->flush())
                    qWarning() << "Could not reply on the Imboard control socket";
            };
            if (command == "QUIT") {
                reply("OK\n");
                emit quitRequested();
            } else if (command == "SHOW") {
                reply("OK\n");
                emit showRequested();
            } else if (command == "TOGGLE") {
                reply("OK\n");
                emit toggleRequested();
            } else {
                reply("ERROR\n");
            }
            socket->disconnectFromServer();
        });
        connect(socket, &QLocalSocket::disconnected, socket, &QObject::deleteLater);
    }
}
