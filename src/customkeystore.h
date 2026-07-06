// SPDX-FileCopyrightText: 2026 AnicetusCer
// SPDX-License-Identifier: GPL-3.0-or-later

#pragma once

#include <QObject>
#include <QString>
#include <QVariantList>

class CustomKeyStore final : public QObject
{
    Q_OBJECT
    Q_PROPERTY(QVariantList assignments READ assignments NOTIFY assignmentsChanged)
    Q_PROPERTY(QString error READ error NOTIFY errorChanged)

public:
    explicit CustomKeyStore(QObject *parent = nullptr);

    QVariantList assignments() const;
    [[nodiscard]] QString error() const;
    Q_INVOKABLE bool commit(const QVariantList &newAssignments);

signals:
    void assignmentsChanged();
    void errorChanged();

private:
    static QVariantList normalized(const QVariantList &assignments);

    QVariantList m_assignments;
    QString m_error;
};
