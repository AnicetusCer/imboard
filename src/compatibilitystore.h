// SPDX-FileCopyrightText: 2026 AnicetusCer
// SPDX-License-Identifier: GPL-3.0-or-later

#pragma once

#include <QObject>

class CompatibilityStore final : public QObject
{
    Q_OBJECT
    Q_PROPERTY(bool nonKdeWarningRequired READ nonKdeWarningRequired
               NOTIFY nonKdeWarningRequiredChanged)

public:
    explicit CompatibilityStore(QObject *parent = nullptr);

    [[nodiscard]] bool nonKdeWarningRequired() const;
    Q_INVOKABLE void dismissNonKdeWarning();

signals:
    void nonKdeWarningRequiredChanged();

private:
    bool m_nonKdeSession = false;
    bool m_nonKdeWarningSeen = false;
};
