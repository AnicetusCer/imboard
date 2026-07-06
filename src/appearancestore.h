// SPDX-FileCopyrightText: 2026 AnicetusCer
// SPDX-License-Identifier: GPL-3.0-or-later

#pragma once

#include <QColor>
#include <QObject>
#include <QString>
#include <QTimer>

class AppearanceStore final : public QObject
{
    Q_OBJECT
    Q_PROPERTY(QString scheme READ scheme NOTIFY appearanceChanged)
    Q_PROPERTY(QColor primary READ primary NOTIFY appearanceChanged)
    Q_PROPERTY(QColor secondary READ secondary NOTIFY appearanceChanged)
    Q_PROPERTY(qreal backdropOpacity READ backdropOpacity NOTIFY appearanceChanged)
    Q_PROPERTY(bool developerPadOnLeft READ developerPadOnLeft NOTIFY appearanceChanged)
    Q_PROPERTY(bool frameBordersVisible READ frameBordersVisible NOTIFY appearanceChanged)
    Q_PROPERTY(bool keyBordersVisible READ keyBordersVisible NOTIFY appearanceChanged)

public:
    explicit AppearanceStore(QObject *parent = nullptr);
    ~AppearanceStore() override;

    [[nodiscard]] QString scheme() const;
    [[nodiscard]] QColor primary() const;
    [[nodiscard]] QColor secondary() const;
    [[nodiscard]] qreal backdropOpacity() const noexcept;
    [[nodiscard]] bool developerPadOnLeft() const noexcept;
    [[nodiscard]] bool frameBordersVisible() const noexcept;
    [[nodiscard]] bool keyBordersVisible() const noexcept;

    Q_INVOKABLE bool selectScheme(const QString &scheme);
    Q_INVOKABLE void setBackdropOpacity(qreal opacity);
    Q_INVOKABLE void toggleDeveloperPadSide();
    Q_INVOKABLE void toggleFrameBorders();
    Q_INVOKABLE void toggleKeyBorders();

signals:
    void appearanceChanged();

private:
    void scheduleSettingsSync();
    static void syncSettings();

    QString m_scheme;
    qreal m_backdropOpacity = 0.5;
    bool m_developerPadOnLeft = false;
    bool m_frameBordersVisible = true;
    bool m_keyBordersVisible = true;
    QTimer m_settingsSyncTimer;
};
