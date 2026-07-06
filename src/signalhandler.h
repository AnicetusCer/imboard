// SPDX-FileCopyrightText: 2026 AnicetusCer
// SPDX-License-Identifier: GPL-3.0-or-later

#pragma once

#include <QObject>

#include <csignal>

class QSocketNotifier;

class SignalHandler final : public QObject
{
    Q_OBJECT

public:
    explicit SignalHandler(QObject *parent = nullptr);
    ~SignalHandler() override;

    bool install();

signals:
    void terminationRequested();

private:
    static void handleSignal(int signalNumber);
    static int s_writeFd;

    int m_readFd = -1;
    int m_writeFd = -1;
    QSocketNotifier *m_notifier = nullptr;
    struct sigaction m_previousTerm {};
    struct sigaction m_previousInt {};
    bool m_handlersInstalled = false;
};
