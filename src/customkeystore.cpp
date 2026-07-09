// SPDX-FileCopyrightText: 2026 AnicetusCer
// SPDX-License-Identifier: GPL-3.0-or-later

#include "customkeystore.h"

#include <QHash>
#include <QSettings>
#include <QSet>
#include <QStringList>
#include <QVariantMap>

namespace
{
constexpr int CustomSlotCount = 16;

QVariantMap emptyAssignment()
{
    return {
        {QStringLiteral("label"), QString()},
        {QStringLiteral("type"), QString()},
        {QStringLiteral("value"), QString()},
        {QStringLiteral("modifiers"), QStringList()},
        {QStringLiteral("key"), QString()},
        {QStringLiteral("icon"), QString()},
        {QStringLiteral("description"), QStringLiteral("Unassigned")},
    };
}

QStringList modifierStrings(const QVariant &value)
{
    const QVariantList items = value.toList();
    if (!items.isEmpty()) {
        QStringList result;
        result.reserve(items.size());
        for (const QVariant &item : items) {
            result.append(item.toString());
        }
        return result;
    }
    return value.toStringList();
}

QString safeDisplayLabel(const QString &label, const QString &value)
{
    static const QHash<QString, QString> emojiLabels{
        {QStringLiteral("👍"), QStringLiteral("UP")},
        {QStringLiteral("👎"), QStringLiteral("DOWN")},
        {QStringLiteral("✅"), QStringLiteral("OK")},
        {QStringLiteral("❌"), QStringLiteral("NO")},
        {QStringLiteral("⚠️"), QStringLiteral("WARN")},
        {QStringLiteral("🐛"), QStringLiteral("BUG")},
        {QStringLiteral("🛠️"), QStringLiteral("TOOLS")},
        {QStringLiteral("💡"), QStringLiteral("IDEA")},
        {QStringLiteral("🚀"), QStringLiteral("SHIP")},
        {QStringLiteral("🔥"), QStringLiteral("HOT")},
        {QStringLiteral("🎉"), QStringLiteral("PARTY")},
        {QStringLiteral("❤️"), QStringLiteral("LOVE")},
        {QStringLiteral("😂"), QStringLiteral("LOL")},
        {QStringLiteral("🤔"), QStringLiteral("THINK")},
        {QStringLiteral("👀"), QStringLiteral("LOOK")},
        {QStringLiteral("📌"), QStringLiteral("PIN")},
    };
    return emojiLabels.value(value, label).left(8);
}

QString emojiIcon(const QString &value)
{
    static const QHash<QString, QString> emojiIcons{
        {QStringLiteral("👍"), QStringLiteral("qrc:/Imboard/assets/twemoji/1f44d.png")},
        {QStringLiteral("👎"), QStringLiteral("qrc:/Imboard/assets/twemoji/1f44e.png")},
        {QStringLiteral("✅"), QStringLiteral("qrc:/Imboard/assets/twemoji/2705.png")},
        {QStringLiteral("❌"), QStringLiteral("qrc:/Imboard/assets/twemoji/274c.png")},
        {QStringLiteral("⚠️"), QStringLiteral("qrc:/Imboard/assets/twemoji/26a0.png")},
        {QStringLiteral("🐛"), QStringLiteral("qrc:/Imboard/assets/twemoji/1f41b.png")},
        {QStringLiteral("🛠️"), QStringLiteral("qrc:/Imboard/assets/twemoji/1f6e0.png")},
        {QStringLiteral("💡"), QStringLiteral("qrc:/Imboard/assets/twemoji/1f4a1.png")},
        {QStringLiteral("🚀"), QStringLiteral("qrc:/Imboard/assets/twemoji/1f680.png")},
        {QStringLiteral("🔥"), QStringLiteral("qrc:/Imboard/assets/twemoji/1f525.png")},
        {QStringLiteral("🎉"), QStringLiteral("qrc:/Imboard/assets/twemoji/1f389.png")},
        {QStringLiteral("❤️"), QStringLiteral("qrc:/Imboard/assets/twemoji/2764.png")},
        {QStringLiteral("😂"), QStringLiteral("qrc:/Imboard/assets/twemoji/1f602.png")},
        {QStringLiteral("🤔"), QStringLiteral("qrc:/Imboard/assets/twemoji/1f914.png")},
        {QStringLiteral("👀"), QStringLiteral("qrc:/Imboard/assets/twemoji/1f440.png")},
        {QStringLiteral("📌"), QStringLiteral("qrc:/Imboard/assets/twemoji/1f4cc.png")},
    };
    return emojiIcons.value(value);
}
}

CustomKeyStore::CustomKeyStore(QObject *parent)
    : QObject(parent)
{
    const QSettings settings;
    m_assignments = normalized(settings.value(QStringLiteral("customKeys/assignments")).toList());
    if (settings.status() != QSettings::NoError)
        m_error = QStringLiteral("Could not read saved custom keys");
}

QVariantList CustomKeyStore::assignments() const
{
    return m_assignments;
}

const QString &CustomKeyStore::error() const noexcept
{
    return m_error;
}

bool CustomKeyStore::commit(const QVariantList &newAssignments)
{
    const QVariantList next = normalized(newAssignments);
    QSettings settings;
    settings.setValue(QStringLiteral("customKeys/assignments"), next);
    settings.sync();
    if (settings.status() != QSettings::NoError) {
        m_error = QStringLiteral("Could not save custom keys");
        emit errorChanged();
        return false;
    }
    if (!m_error.isEmpty()) {
        m_error.clear();
        emit errorChanged();
    }
    if (m_assignments == next) {
        return true;
    }
    m_assignments = next;
    emit assignmentsChanged();
    return true;
}

QVariantList CustomKeyStore::normalized(const QVariantList &assignments)
{
    QVariantList result;
    result.reserve(CustomSlotCount);
    for (int index = 0; index < CustomSlotCount; ++index) {
        if (index >= assignments.size()) {
            result.append(emptyAssignment());
            continue;
        }

        const QVariantMap candidate = assignments.at(index).toMap();
        const QString type = candidate.value(QStringLiteral("type")).toString();
        const QString value = candidate.value(QStringLiteral("value")).toString();
        const QString key = candidate.value(QStringLiteral("key")).toString();
        const QStringList modifiers = modifierStrings(candidate.value(QStringLiteral("modifiers")));
        const bool isSingleAction = (type == QLatin1String("key") || type == QLatin1String("text"))
                                    && !value.isEmpty();
        const QSet<QString> allowedModifiers{
            QStringLiteral("Ctrl"), QStringLiteral("Shift"),
            QStringLiteral("Alt"), QStringLiteral("Meta")};
        bool isChord = type == QLatin1String("chord") && !key.isEmpty()
                       && !modifiers.isEmpty() && modifiers.size() <= 3;
        QSet<QString> seenModifiers;
        for (const QString &modifier : modifiers) {
            if (!allowedModifiers.contains(modifier) || seenModifiers.contains(modifier)) {
                isChord = false;
                break;
            }
            seenModifiers.insert(modifier);
        }
        if (!isSingleAction && !isChord) {
            result.append(emptyAssignment());
            continue;
        }

        QVariantMap accepted;
        accepted.insert(QStringLiteral("label"),
                        safeDisplayLabel(candidate.value(QStringLiteral("label")).toString(), value));
        accepted.insert(QStringLiteral("type"), type);
        accepted.insert(QStringLiteral("value"), isSingleAction ? value.left(32) : QString());
        accepted.insert(QStringLiteral("modifiers"), isChord ? modifiers : QStringList());
        accepted.insert(QStringLiteral("key"), isChord ? key.left(32) : QString());
        accepted.insert(QStringLiteral("icon"), type == QLatin1String("text")
                                                ? emojiIcon(value) : QString());
        accepted.insert(QStringLiteral("description"),
                        candidate.value(QStringLiteral("description")).toString().left(80));
        result.append(accepted);
    }
    return result;
}
