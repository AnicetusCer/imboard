// SPDX-FileCopyrightText: 2026 AnicetusCer
// SPDX-License-Identifier: GPL-3.0-or-later

#include "keyboardlayoutstore.h"

#include <QDir>
#include <QDebug>
#include <QFile>
#include <QJsonArray>
#include <QJsonDocument>
#include <QJsonObject>
#include <QRegularExpression>
#include <QSettings>
#include <QVariantMap>

KeyboardLayoutStore::KeyboardLayoutStore(QObject *parent)
    : QObject(parent)
{
    loadLayouts();
    const QSettings settings;
    const QString saved = settings.value(QStringLiteral("keyboard/layout"),
                                         QStringLiteral("us")).toString();
    if (settings.status() != QSettings::NoError)
        qWarning() << "Could not read the saved keyboard layout; using a default";
    if (m_layouts.contains(saved)) {
        m_layoutId = saved;
    } else if (m_layouts.contains(QStringLiteral("us"))) {
        m_layoutId = QStringLiteral("us");
    } else if (!m_layouts.isEmpty()) {
        m_layoutId = m_layouts.firstKey();
    }
}

QString KeyboardLayoutStore::layoutId() const
{
    return m_layoutId;
}

QVariantList KeyboardLayoutStore::availableLayouts() const
{
    QVariantList result;
    for (auto iterator = m_layouts.cbegin(); iterator != m_layouts.cend(); ++iterator) {
        result.append(QVariantMap{
            {QStringLiteral("id"), iterator.key()},
            {QStringLiteral("name"), iterator.value().name},
        });
    }
    return result;
}

QVariantList KeyboardLayoutStore::rows() const
{
    return m_layouts.value(m_layoutId).rows;
}

QString KeyboardLayoutStore::error() const
{
    return m_error;
}

bool KeyboardLayoutStore::selectLayout(const QString &layoutId)
{
    if (!m_layouts.contains(layoutId)) {
        m_error = QStringLiteral("Unknown keyboard layout");
        emit errorChanged();
        return false;
    }
    if (m_layoutId == layoutId) {
        if (!m_error.isEmpty()) {
            m_error.clear();
            emit errorChanged();
        }
        return true;
    }
    QSettings settings;
    settings.setValue(QStringLiteral("keyboard/layout"), layoutId);
    settings.sync();
    if (settings.status() != QSettings::NoError) {
        qWarning().noquote() << "Could not save keyboard layout" << layoutId;
        m_error = QStringLiteral("Could not save keyboard layout");
        emit errorChanged();
        return false;
    }
    if (!m_error.isEmpty()) {
        m_error.clear();
        emit errorChanged();
    }
    m_layoutId = layoutId;
    emit layoutChanged();
    return true;
}

void KeyboardLayoutStore::loadLayouts()
{
    static const QRegularExpression validId(QStringLiteral("^[a-z0-9_-]{2,16}$"));
    const QDir directory(QStringLiteral(":/Imboard/layouts"));
    const QStringList files = directory.entryList({QStringLiteral("*.json")}, QDir::Files);
    for (const QString &fileName : files) {
        QFile file(directory.filePath(fileName));
        if (!file.open(QIODevice::ReadOnly)) {
            qWarning().noquote() << "Could not read keyboard layout" << fileName
                                 << file.errorString();
            continue;
        }
        QJsonParseError error;
        const QJsonDocument document = QJsonDocument::fromJson(file.readAll(), &error);
        if (error.error != QJsonParseError::NoError || !document.isObject()) {
            qWarning().noquote() << "Ignoring invalid keyboard layout" << fileName
                                 << error.errorString();
            continue;
        }
        const QJsonObject object = document.object();
        const QString id = object.value(QStringLiteral("id")).toString();
        const QString name = object.value(QStringLiteral("name")).toString().left(40);
        const QVariantList rows = normalizedRows(object.value(QStringLiteral("rows")).toArray().toVariantList());
        if (!validId.match(id).hasMatch() || name.isEmpty() || rows.isEmpty()) {
            qWarning().noquote() << "Ignoring malformed keyboard layout" << fileName;
            continue;
        }
        m_layouts.insert(id, Layout{name, rows});
    }
    if (m_layouts.isEmpty()) {
        qCritical() << "No valid built-in keyboard layouts were found";
    }
}

QVariantList KeyboardLayoutStore::normalizedRows(const QVariantList &rows)
{
    if (rows.size() < 4 || rows.size() > 8) {
        return {};
    }
    const QStringList allowedTypes{
        QStringLiteral("key"), QStringLiteral("text"), QStringLiteral("letter"),
        QStringLiteral("modifier"), QStringLiteral("lock")};
    QVariantList acceptedRows;
    for (const QVariant &rowValue : rows) {
        const QVariantList row = rowValue.toList();
        if (row.size() < 2 || row.size() > 20) {
            return {};
        }
        QVariantList acceptedRow;
        for (const QVariant &keyValue : row) {
            const QVariantMap key = keyValue.toMap();
            const QString label = key.value(QStringLiteral("label")).toString().left(10);
            const QString type = key.value(QStringLiteral("type")).toString();
            const QString value = key.value(QStringLiteral("value")).toString().left(16);
            if (label.isEmpty() || !allowedTypes.contains(type) || value.isEmpty()) {
                return {};
            }
            QVariantMap accepted{
                {QStringLiteral("label"), label},
                {QStringLiteral("type"), type},
                {QStringLiteral("value"), value},
            };
            const QString shiftedLabel = key.value(QStringLiteral("shiftedLabel")).toString().left(4);
            const QString shiftedValue = key.value(QStringLiteral("shiftedValue")).toString().left(8);
            if (!shiftedLabel.isEmpty()) accepted.insert(QStringLiteral("shiftedLabel"), shiftedLabel);
            if (!shiftedValue.isEmpty()) accepted.insert(QStringLiteral("shiftedValue"), shiftedValue);
            const int width = key.value(QStringLiteral("width"), 46).toInt();
            accepted.insert(QStringLiteral("width"), qBound(32, width, 320));
            acceptedRow.append(accepted);
        }
        acceptedRows.append(QVariant(acceptedRow));
    }
    return acceptedRows;
}
