// SPDX-FileCopyrightText: 2026 AnicetusCer
// SPDX-License-Identifier: GPL-3.0-or-later

#pragma once

#include <QMap>
#include <QObject>
#include <QString>
#include <QVariantList>

class KeyboardLayoutStore final : public QObject
{
    Q_OBJECT
    Q_PROPERTY(QString layoutId READ layoutId NOTIFY layoutChanged)
    Q_PROPERTY(QVariantList availableLayouts READ availableLayouts CONSTANT)
    Q_PROPERTY(QVariantList rows READ rows NOTIFY layoutChanged)
    Q_PROPERTY(QString error READ error NOTIFY errorChanged)

public:
    explicit KeyboardLayoutStore(QObject *parent = nullptr);

    [[nodiscard]] QString layoutId() const;
    [[nodiscard]] QVariantList availableLayouts() const;
    [[nodiscard]] QVariantList rows() const;
    [[nodiscard]] QString error() const;

    Q_INVOKABLE bool selectLayout(const QString &layoutId);

signals:
    void layoutChanged();
    void errorChanged();

private:
    struct Layout
    {
        QString name;
        QVariantList rows;
    };

    void loadLayouts();
    static QVariantList normalizedRows(const QVariantList &rows);

    QMap<QString, Layout> m_layouts;
    QString m_layoutId;
    QString m_error;
};
