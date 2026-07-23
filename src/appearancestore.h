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
    Q_PROPERTY(bool customPadOnlyEnabled READ customPadOnlyEnabled NOTIFY appearanceChanged)
    Q_PROPERTY(int customPadKeyCount READ customPadKeyCount NOTIFY appearanceChanged)
    Q_PROPERTY(int customPadColumns READ customPadColumns NOTIFY appearanceChanged)
    Q_PROPERTY(int developerPadPageIndex READ developerPadPageIndex NOTIFY appearanceChanged)

public:
    explicit AppearanceStore(QObject *parent = nullptr);
    ~AppearanceStore() override;

    [[nodiscard]] const QString &scheme() const noexcept;
    [[nodiscard]] QColor primary() const;
    [[nodiscard]] QColor secondary() const;
    [[nodiscard]] qreal backdropOpacity() const noexcept;
    [[nodiscard]] bool developerPadOnLeft() const noexcept;
    [[nodiscard]] bool frameBordersVisible() const noexcept;
    [[nodiscard]] bool keyBordersVisible() const noexcept;
    [[nodiscard]] bool customPadOnlyEnabled() const noexcept;
    [[nodiscard]] int customPadKeyCount() const noexcept;
    [[nodiscard]] int customPadColumns() const noexcept;
    [[nodiscard]] int developerPadPageIndex() const noexcept;

    Q_INVOKABLE bool selectScheme(const QString &schemeId);
    Q_INVOKABLE void setBackdropOpacity(qreal opacity);
    Q_INVOKABLE void toggleDeveloperPadSide();
    Q_INVOKABLE void toggleFrameBorders();
    Q_INVOKABLE void toggleKeyBorders();
    Q_INVOKABLE void setCustomPadOnlyEnabled(bool enabled);
    Q_INVOKABLE void setCustomPadKeyCount(int count);
    Q_INVOKABLE void setCustomPadColumns(int columns);
    Q_INVOKABLE void setDeveloperPadPageIndex(int index);

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
    bool m_customPadOnlyEnabled = false;
    int m_customPadKeyCount = 9;
    int m_customPadColumns = 0;
    int m_developerPadPageIndex = 0;
    QTimer m_settingsSyncTimer;
};
