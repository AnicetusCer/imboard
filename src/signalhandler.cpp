// SPDX-FileCopyrightText: 2026 AnicetusCer
// SPDX-License-Identifier: GPL-3.0-or-later

#include "signalhandler.h"

#include <QDebug>
#include <QSocketNotifier>

#include <csignal>
#include <fcntl.h>
#include <unistd.h>

int SignalHandler::s_writeFd = -1;

SignalHandler::SignalHandler(QObject *parent)
    : QObject(parent)
{
}

SignalHandler::~SignalHandler()
{
    s_writeFd = -1;
    if (m_handlersInstalled) {
        if (sigaction(SIGTERM, &m_previousTerm, nullptr) != 0
            || sigaction(SIGINT, &m_previousInt, nullptr) != 0) {
            qWarning() << "Could not restore the previous process signal handlers";
        }
    }
    if (m_readFd >= 0) {
        close(m_readFd);
    }
    if (m_writeFd >= 0) {
        close(m_writeFd);
    }
}

bool SignalHandler::install()
{
    const auto closeDescriptors = [this]() {
        s_writeFd = -1;
        if (m_readFd >= 0) close(m_readFd);
        if (m_writeFd >= 0) close(m_writeFd);
        m_readFd = -1;
        m_writeFd = -1;
    };

    int descriptors[2];
    if (pipe(descriptors) != 0) {
        return false;
    }
    m_readFd = descriptors[0];
    m_writeFd = descriptors[1];
    s_writeFd = m_writeFd;

    // cppcheck-suppress useStlAlgorithm
    for (const int descriptor : descriptors) {
        const int flags = fcntl(descriptor, F_GETFL, 0);
        const int descriptorFlags = fcntl(descriptor, F_GETFD, 0);
        if (flags < 0 || descriptorFlags < 0
            || fcntl(descriptor, F_SETFL, flags | O_NONBLOCK) < 0
            || fcntl(descriptor, F_SETFD, descriptorFlags | FD_CLOEXEC) < 0) {
            closeDescriptors();
            return false;
        }
    }

    struct sigaction action {};
    action.sa_handler = &SignalHandler::handleSignal;
    sigemptyset(&action.sa_mask);
    action.sa_flags = SA_RESTART;
    if (sigaction(SIGTERM, &action, &m_previousTerm) != 0) {
        closeDescriptors();
        return false;
    }
    if (sigaction(SIGINT, &action, &m_previousInt) != 0) {
        if (sigaction(SIGTERM, &m_previousTerm, nullptr) != 0)
            qWarning() << "Could not roll back the SIGTERM handler";
        closeDescriptors();
        return false;
    }
    m_handlersInstalled = true;

    m_notifier = new QSocketNotifier(m_readFd, QSocketNotifier::Read, this);
    connect(m_notifier, &QSocketNotifier::activated, this, [this]() {
        char buffer[32];
        while (read(m_readFd, buffer, sizeof(buffer)) > 0) {
        }
        emit terminationRequested();
    });
    return true;
}

void SignalHandler::handleSignal(int signalNumber)
{
    const char value = static_cast<char>(signalNumber);
    if (s_writeFd >= 0) {
        // There is no safe recovery operation inside a signal handler. A full
        // non-blocking pipe is equivalent to a notification already pending.
        const ssize_t ignored = write(s_writeFd, &value, sizeof(value));
        Q_UNUSED(ignored)
    }
}
