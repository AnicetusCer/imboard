// SPDX-FileCopyrightText: 2026 AnicetusCer
// SPDX-License-Identifier: GPL-3.0-or-later

#include "compatibilitystore.h"

#include "appmetadata.h"

#include <QCoreApplication>
#include <QObject>
#include <QSettings>
#include <QSignalSpy>
#include <QTest>

class CompatibilityStoreTest final : public QObject
{
    Q_OBJECT

private slots:
    void initTestCase()
    {
        QCoreApplication::setOrganizationName(QString::fromUtf8(Imboard::OrganizationName));
        QCoreApplication::setApplicationName(QString::fromUtf8(Imboard::AppName));
    }

    void init()
    {
        QSettings settings;
        settings.clear();
        settings.sync();
    }

    void kdeSessionDoesNotRequireWarning()
    {
        qputenv("XDG_CURRENT_DESKTOP", "KDE");
        CompatibilityStore store;
        QVERIFY(!store.nonKdeWarningRequired());
    }

    void nonKdeSessionRequiresWarningUntilDismissed()
    {
        qputenv("XDG_CURRENT_DESKTOP", "GNOME");
        CompatibilityStore store;
        QVERIFY(store.nonKdeWarningRequired());

        QSignalSpy spy(&store, &CompatibilityStore::nonKdeWarningRequiredChanged);
        store.dismissNonKdeWarning();
        QVERIFY(!store.nonKdeWarningRequired());
        QCOMPARE(spy.count(), 1);

        CompatibilityStore reloaded;
        QVERIFY(!reloaded.nonKdeWarningRequired());
    }
};

QTEST_MAIN(CompatibilityStoreTest)

#include "compatibilitystore_test.moc"
