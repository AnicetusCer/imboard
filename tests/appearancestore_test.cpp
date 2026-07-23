// SPDX-FileCopyrightText: 2026 AnicetusCer
// SPDX-License-Identifier: GPL-3.0-or-later

#include "appearancestore.h"

#include <QSettings>
#include <QTest>

class AppearanceStoreTest final : public QObject
{
    Q_OBJECT

private slots:
    void initTestCase()
    {
        QCoreApplication::setOrganizationName(QStringLiteral("ImboardTests"));
        QCoreApplication::setApplicationName(QStringLiteral("AppearanceStore"));
        QSettings().clear();
    }

    void validatesAndPersistsAppearance()
    {
        AppearanceStore initial;
        QCOMPARE(initial.scheme(), QStringLiteral("cyber"));
        QCOMPARE(initial.backdropOpacity(), 0.5);
        QVERIFY(!initial.developerPadOnLeft());
        QVERIFY(initial.frameBordersVisible());
        QVERIFY(initial.keyBordersVisible());
        QVERIFY(!initial.customPadOnlyEnabled());
        QCOMPARE(initial.customPadKeyCount(), 9);
        QCOMPARE(initial.customPadColumns(), 0);
        QCOMPARE(initial.developerPadPageIndex(), 0);
        QVERIFY(!initial.selectScheme(QStringLiteral("unknown")));
        QVERIFY(initial.selectScheme(QStringLiteral("red")));
        QCOMPARE(initial.primary(), QColor(QStringLiteral("#ff3b4f")));
        QVERIFY(initial.selectScheme(QStringLiteral("matrix")));
        QCOMPARE(initial.primary(), QColor(QStringLiteral("#65ff70")));
        initial.setBackdropOpacity(0.42);
        initial.toggleDeveloperPadSide();
        initial.toggleFrameBorders();
        initial.toggleKeyBorders();
        initial.setCustomPadOnlyEnabled(true);
        initial.setCustomPadKeyCount(12);
        initial.setCustomPadColumns(4);
        initial.setDeveloperPadPageIndex(5);

        AppearanceStore reloaded;
        QCOMPARE(reloaded.scheme(), QStringLiteral("matrix"));
        QCOMPARE(reloaded.backdropOpacity(), 0.42);
        QVERIFY(reloaded.developerPadOnLeft());
        QVERIFY(!reloaded.frameBordersVisible());
        QVERIFY(!reloaded.keyBordersVisible());
        QVERIFY(reloaded.customPadOnlyEnabled());
        QCOMPARE(reloaded.customPadKeyCount(), 12);
        QCOMPARE(reloaded.customPadColumns(), 4);
        QCOMPARE(reloaded.developerPadPageIndex(), 5);
        reloaded.setBackdropOpacity(4.0);
        QCOMPARE(reloaded.backdropOpacity(), 1.0);
        reloaded.setCustomPadKeyCount(99);
        QCOMPARE(reloaded.customPadKeyCount(), 16);
        reloaded.setCustomPadKeyCount(-3);
        QCOMPARE(reloaded.customPadKeyCount(), 1);
        reloaded.setCustomPadColumns(99);
        QCOMPARE(reloaded.customPadColumns(), 4);
        reloaded.setCustomPadColumns(-3);
        QCOMPARE(reloaded.customPadColumns(), 0);
        reloaded.setDeveloperPadPageIndex(999);
        QCOMPARE(reloaded.developerPadPageIndex(), 255);
        reloaded.setDeveloperPadPageIndex(-3);
        QCOMPARE(reloaded.developerPadPageIndex(), 0);
    }
};

QTEST_GUILESS_MAIN(AppearanceStoreTest)

#include "appearancestore_test.moc"
