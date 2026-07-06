// SPDX-FileCopyrightText: 2026 AnicetusCer
// SPDX-License-Identifier: GPL-3.0-or-later

#include "appearancestore.h"

#include <QDebug>
#include <QHash>
#include <QSettings>
#include <QtGlobal>

namespace
{
struct Palette
{
    QColor primary;
    QColor secondary;
};

const QHash<QString, Palette> &palettes()
{
    static const QHash<QString, Palette> values{
        {QStringLiteral("cyber"), {QColor(QStringLiteral("#48f3ff")), QColor(QStringLiteral("#ef64ff"))}},
        {QStringLiteral("matrix"), {QColor(QStringLiteral("#65ff70")), QColor(QStringLiteral("#c6ff4a"))}},
        {QStringLiteral("amber"), {QColor(QStringLiteral("#ffb43b")), QColor(QStringLiteral("#fff06a"))}},
        {QStringLiteral("ice"), {QColor(QStringLiteral("#69a7ff")), QColor(QStringLiteral("#e8f3ff"))}},
        {QStringLiteral("violet"), {QColor(QStringLiteral("#b77cff")), QColor(QStringLiteral("#ff67d4"))}},
        {QStringLiteral("red"), {QColor(QStringLiteral("#ff3b4f")), QColor(QStringLiteral("#ff8a65"))}},
    };
    return values;
}
}

AppearanceStore::AppearanceStore(QObject *parent)
    : QObject(parent)
{
    m_settingsSyncTimer.setSingleShot(true);
    m_settingsSyncTimer.setInterval(300);
    connect(&m_settingsSyncTimer, &QTimer::timeout,
            this, &AppearanceStore::syncSettings);

    const QSettings settings;
    const QString savedScheme = settings.value(QStringLiteral("appearance/scheme"),
                                                QStringLiteral("cyber")).toString();
    m_scheme = palettes().contains(savedScheme) ? savedScheme : QStringLiteral("cyber");
    m_backdropOpacity = qBound(0.0,
                               settings.value(QStringLiteral("appearance/backdropOpacity"), 0.5).toDouble(),
                               1.0);
    m_developerPadOnLeft = settings.value(QStringLiteral("appearance/developerPadOnLeft"), false).toBool();
    m_frameBordersVisible = settings.value(QStringLiteral("appearance/frameBordersVisible"), true).toBool();
    m_keyBordersVisible = settings.value(QStringLiteral("appearance/keyBordersVisible"), true).toBool();
    if (settings.status() != QSettings::NoError)
        qWarning() << "Could not read appearance settings; defaults will be used";
}

AppearanceStore::~AppearanceStore()
{
    if (m_settingsSyncTimer.isActive()) syncSettings();
}

QString AppearanceStore::scheme() const
{
    return m_scheme;
}

QColor AppearanceStore::primary() const
{
    return palettes().value(m_scheme).primary;
}

QColor AppearanceStore::secondary() const
{
    return palettes().value(m_scheme).secondary;
}

qreal AppearanceStore::backdropOpacity() const noexcept
{
    return m_backdropOpacity;
}

bool AppearanceStore::developerPadOnLeft() const noexcept
{
    return m_developerPadOnLeft;
}

bool AppearanceStore::frameBordersVisible() const noexcept
{
    return m_frameBordersVisible;
}

bool AppearanceStore::keyBordersVisible() const noexcept
{
    return m_keyBordersVisible;
}

bool AppearanceStore::selectScheme(const QString &scheme)
{
    if (!palettes().contains(scheme)) {
        return false;
    }
    if (m_scheme == scheme) {
        return true;
    }
    m_scheme = scheme;
    QSettings().setValue(QStringLiteral("appearance/scheme"), m_scheme);
    scheduleSettingsSync();
    emit appearanceChanged();
    return true;
}

void AppearanceStore::setBackdropOpacity(qreal opacity)
{
    const qreal bounded = qBound(0.0, opacity, 1.0);
    if (qFuzzyCompare(m_backdropOpacity, bounded)) {
        return;
    }
    m_backdropOpacity = bounded;
    QSettings().setValue(QStringLiteral("appearance/backdropOpacity"), m_backdropOpacity);
    scheduleSettingsSync();
    emit appearanceChanged();
}

void AppearanceStore::toggleDeveloperPadSide()
{
    m_developerPadOnLeft = !m_developerPadOnLeft;
    QSettings().setValue(QStringLiteral("appearance/developerPadOnLeft"), m_developerPadOnLeft);
    scheduleSettingsSync();
    emit appearanceChanged();
}

void AppearanceStore::toggleFrameBorders()
{
    m_frameBordersVisible = !m_frameBordersVisible;
    QSettings().setValue(QStringLiteral("appearance/frameBordersVisible"), m_frameBordersVisible);
    scheduleSettingsSync();
    emit appearanceChanged();
}

void AppearanceStore::toggleKeyBorders()
{
    m_keyBordersVisible = !m_keyBordersVisible;
    QSettings().setValue(QStringLiteral("appearance/keyBordersVisible"), m_keyBordersVisible);
    scheduleSettingsSync();
    emit appearanceChanged();
}

void AppearanceStore::scheduleSettingsSync()
{
    m_settingsSyncTimer.start();
}

void AppearanceStore::syncSettings()
{
    QSettings settings;
    settings.sync();
    if (settings.status() != QSettings::NoError)
        qWarning() << "Could not save appearance settings";
}
