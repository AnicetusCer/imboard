// SPDX-FileCopyrightText: 2026 AnicetusCer
// SPDX-License-Identifier: GPL-3.0-or-later

#include "compatibilitystore.h"

#include <QSettings>

namespace
{
constexpr auto NonKdeWarningSeenKey = "compatibility/nonKdeWarningSeen";

bool isKdeSession()
{
    const QString desktop =
        QString::fromLocal8Bit(qgetenv("XDG_CURRENT_DESKTOP")).toLower();
    return desktop.split(QLatin1Char(':'), Qt::SkipEmptyParts).contains(QStringLiteral("kde"));
}
}

CompatibilityStore::CompatibilityStore(QObject *parent)
    : QObject(parent)
    , m_nonKdeSession(!isKdeSession())
{
    const QSettings settings;
    m_nonKdeWarningSeen = settings.value(QString::fromLatin1(NonKdeWarningSeenKey),
                                         false).toBool();
    if (settings.status() != QSettings::NoError)
        m_nonKdeWarningSeen = false;
}

bool CompatibilityStore::nonKdeWarningRequired() const
{
    return m_nonKdeSession && !m_nonKdeWarningSeen;
}

void CompatibilityStore::dismissNonKdeWarning()
{
    if (!m_nonKdeSession || m_nonKdeWarningSeen) return;

    QSettings settings;
    settings.setValue(QString::fromLatin1(NonKdeWarningSeenKey), true);
    settings.sync();
    if (settings.status() != QSettings::NoError) return;

    m_nonKdeWarningSeen = true;
    emit nonKdeWarningRequiredChanged();
}
