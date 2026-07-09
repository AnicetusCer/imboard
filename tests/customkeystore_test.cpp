// SPDX-FileCopyrightText: 2026 AnicetusCer
// SPDX-License-Identifier: GPL-3.0-or-later

#include "customkeystore.h"

#include <QSettings>
#include <QTest>
#include <QVariantMap>

class CustomKeyStoreTest final : public QObject
{
    Q_OBJECT

private slots:
    void initTestCase()
    {
        QCoreApplication::setOrganizationName(QStringLiteral("ImboardTests"));
        QCoreApplication::setApplicationName(QStringLiteral("CustomKeyStore"));
        QSettings().clear();
    }

    void persistsSixNormalizedSlots()
    {
        CustomKeyStore initial;
        QCOMPARE(initial.assignments().size(), 16);

        QVariantList assignments;
        assignments.append(QVariantMap{
            {QStringLiteral("label"), QStringLiteral("Esc")},
            {QStringLiteral("type"), QStringLiteral("key")},
            {QStringLiteral("value"), QStringLiteral("Escape")},
            {QStringLiteral("description"), QStringLiteral("Escape")},
        });
        assignments.append(QVariantMap{
            {QStringLiteral("label"), QStringLiteral("|")},
            {QStringLiteral("type"), QStringLiteral("text")},
            {QStringLiteral("value"), QStringLiteral("|")},
            {QStringLiteral("description"), QStringLiteral("Pipe")},
        });
        assignments.append(QVariantMap{
            {QStringLiteral("label"), QStringLiteral("RDO")},
            {QStringLiteral("type"), QStringLiteral("chord")},
            {QStringLiteral("modifiers"), QVariantList{QStringLiteral("Ctrl"),
                                                        QStringLiteral("Shift")}},
            {QStringLiteral("key"), QStringLiteral("Z")},
            {QStringLiteral("description"), QStringLiteral("Redo — Ctrl+Shift+Z")},
        });
        assignments.append(QVariantMap{
            {QStringLiteral("label"), QStringLiteral("unsafe")},
            {QStringLiteral("type"), QStringLiteral("command")},
            {QStringLiteral("value"), QStringLiteral("anything")},
        });
        assignments.append(QVariantMap{
            {QStringLiteral("label"), QStringLiteral("invalid")},
            {QStringLiteral("type"), QStringLiteral("chord")},
            {QStringLiteral("modifiers"), QVariantList{QStringLiteral("Ctrl"),
                                                        QStringLiteral("Root")}},
            {QStringLiteral("key"), QStringLiteral("X")},
        });
        assignments.append(QVariantMap{
            {QStringLiteral("label"), QStringLiteral("🐛")},
            {QStringLiteral("type"), QStringLiteral("text")},
            {QStringLiteral("value"), QStringLiteral("🐛")},
            {QStringLiteral("description"), QStringLiteral("Emoji — bug")},
        });

        QVERIFY(initial.commit(assignments));

        CustomKeyStore reloaded;
        QCOMPARE(reloaded.assignments().size(), 16);
        QCOMPARE(reloaded.assignments().at(0).toMap().value(QStringLiteral("value")).toString(),
                 QStringLiteral("Escape"));
        QCOMPARE(reloaded.assignments().at(1).toMap().value(QStringLiteral("value")).toString(),
                 QStringLiteral("|"));
        QCOMPARE(reloaded.assignments().at(2).toMap().value(QStringLiteral("type")).toString(),
                 QStringLiteral("chord"));
        QCOMPARE(reloaded.assignments().at(2).toMap().value(QStringLiteral("modifiers")).toStringList(),
                 QStringList({QStringLiteral("Ctrl"), QStringLiteral("Shift")}));
        QCOMPARE(reloaded.assignments().at(2).toMap().value(QStringLiteral("key")).toString(),
                 QStringLiteral("Z"));
        QVERIFY(reloaded.assignments().at(3).toMap().value(QStringLiteral("type")).toString().isEmpty());
        QVERIFY(reloaded.assignments().at(4).toMap().value(QStringLiteral("type")).toString().isEmpty());
        QCOMPARE(reloaded.assignments().at(5).toMap().value(QStringLiteral("label")).toString(),
                 QStringLiteral("BUG"));
        QCOMPARE(reloaded.assignments().at(5).toMap().value(QStringLiteral("value")).toString(),
                 QStringLiteral("🐛"));
        QCOMPARE(reloaded.assignments().at(5).toMap().value(QStringLiteral("icon")).toString(),
                 QStringLiteral("qrc:/Imboard/assets/twemoji/1f41b.png"));
        QVERIFY(reloaded.assignments().at(6).toMap().value(QStringLiteral("type")).toString().isEmpty());
        QVERIFY(reloaded.assignments().at(7).toMap().value(QStringLiteral("type")).toString().isEmpty());
        QVERIFY(reloaded.assignments().at(8).toMap().value(QStringLiteral("type")).toString().isEmpty());
        QVERIFY(reloaded.assignments().at(15).toMap().value(QStringLiteral("type")).toString().isEmpty());
        QVERIFY(reloaded.error().isEmpty());
    }

    void reportsPersistenceFailure()
    {
        QSettings::setDefaultFormat(QSettings::IniFormat);
        QSettings::setPath(QSettings::IniFormat, QSettings::UserScope,
                           QStringLiteral("/proc/imboard-unwritable"));
        CustomKeyStore store;
        const QVariantList assignments{QVariantMap{
            {QStringLiteral("label"), QStringLiteral("|")},
            {QStringLiteral("type"), QStringLiteral("text")},
            {QStringLiteral("value"), QStringLiteral("|")},
        }};

        QVERIFY(!store.commit(assignments));
        QVERIFY(!store.error().isEmpty());
    }
};

QTEST_GUILESS_MAIN(CustomKeyStoreTest)

#include "customkeystore_test.moc"
