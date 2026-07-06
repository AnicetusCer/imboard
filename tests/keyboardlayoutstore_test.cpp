// SPDX-FileCopyrightText: 2026 AnicetusCer
// SPDX-License-Identifier: GPL-3.0-or-later

#include "keyboardlayoutstore.h"

#include <QSettings>
#include <QTest>
#include <QVariantMap>

class KeyboardLayoutStoreTest final : public QObject
{
    Q_OBJECT

private slots:
    void initTestCase()
    {
        QCoreApplication::setOrganizationName(QStringLiteral("ImboardTests"));
        QCoreApplication::setApplicationName(QStringLiteral("KeyboardLayoutStore"));
        QSettings().clear();
    }

    void discoversSelectsAndPersistsLayouts()
    {
        KeyboardLayoutStore initial;
        QCOMPARE(initial.layoutId(), QStringLiteral("us"));
        QCOMPARE(initial.availableLayouts().size(), 2);
        QCOMPARE(initial.rows().size(), 5);
        QVERIFY(!initial.selectLayout(QStringLiteral("../../unsafe")));
        QVERIFY(initial.selectLayout(QStringLiteral("gb")));

        const QVariantList numberRow = initial.rows().at(0).toList();
        const QVariantMap threeKey = numberRow.at(4).toMap();
        QCOMPARE(threeKey.value(QStringLiteral("shiftedValue")).toString(), QStringLiteral("£"));

        KeyboardLayoutStore reloaded;
        QCOMPARE(reloaded.layoutId(), QStringLiteral("gb"));
        QCOMPARE(reloaded.rows().size(), 5);
    }

    void rejectsLayoutChangeWhenPersistenceFails()
    {
        QSettings::setDefaultFormat(QSettings::IniFormat);
        QSettings::setPath(QSettings::IniFormat, QSettings::UserScope,
                           QStringLiteral("/proc/imboard-unwritable"));
        KeyboardLayoutStore store;

        QCOMPARE(store.layoutId(), QStringLiteral("us"));
        QVERIFY(!store.selectLayout(QStringLiteral("gb")));
        QCOMPARE(store.layoutId(), QStringLiteral("us"));
        QVERIFY(!store.error().isEmpty());
    }
};

QTEST_GUILESS_MAIN(KeyboardLayoutStoreTest)

#include "keyboardlayoutstore_test.moc"
