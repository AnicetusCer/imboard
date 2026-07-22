// SPDX-FileCopyrightText: 2026 AnicetusCer
// SPDX-License-Identifier: GPL-3.0-or-later

#include "instancecontroller.h"

#include "appmetadata.h"

#include <QDBusConnection>
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

InstanceController::~InstanceController()
{
    if (m_busServiceRegistered) {
        if (!QDBusConnection::sessionBus().unregisterService(
                QString::fromUtf8(Imboard::AppId))) {
            qWarning() << "Could not release the Imboard session-bus name";
        }
    }
}

bool InstanceController::start()
{
    m_error.clear();
    const QString lockFilePath = lockPath();
    const QString serverPath = socketPath();
    if (lockFilePath.isEmpty() || serverPath.isEmpty()) {
        m_error = QStringLiteral("Could not create a private runtime directory");
        return false;
    }

    QDBusConnection sessionBus = QDBusConnection::sessionBus();
    if (sessionBus.isConnected()) {
        m_busServiceRegistered = sessionBus.registerService(
            QString::fromUtf8(Imboard::AppId));
        if (!m_busServiceRegistered) {
            m_error = QStringLiteral("Another Imboard instance is already running");
            return false;
        }
    } else {
        qWarning() << "The session bus is unavailable; stale-instance recovery is disabled";
    }

    m_lock = std::make_unique<QLockFile>(lockFilePath);
    m_lock->setStaleLockTime(0);
    if (!m_lock->tryLock(0)) {
        const bool recoverable = m_busServiceRegistered
                                 && m_lock->error() == QLockFile::LockFailedError;
        if (!recoverable) {
            m_error = QStringLiteral("The Imboard instance lock is already held or unavailable");
            return false;
        }

        // Flatpak gives each sandbox its own PID namespace, so every Imboard
        // process can be recorded as PID 2. QLockFile therefore cannot tell a
        // crashed Flatpak process from the new process. Owning the application
        // D-Bus name proves that no current Imboard instance using this guard is
        // alive, so it is safe to replace the abandoned long-lived lock.
        const bool removedLock = m_lock->removeStaleLockFile();
        if (!m_lock->tryLock(0)) {
            m_error = QStringLiteral("Could not recover the abandoned Imboard instance lock");
            return false;
        }
        qWarning() << "Recovered abandoned Imboard runtime state"
                   << (removedLock ? QStringLiteral("after removing its stale lock")
                                   : QStringLiteral("after its stale lock disappeared"));
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
