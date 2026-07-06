// SPDX-FileCopyrightText: 2026 AnicetusCer
// SPDX-License-Identifier: GPL-3.0-or-later

#include "appmetadata.h"
#include "startupmanager.h"

#include <QFile>
#include <QSettings>
#include <QStandardPaths>
#include <QTest>

class StartupManagerTest final : public QObject
{
    Q_OBJECT

private slots:
    void init()
    {
        QSettings().clear();
    }

    void createsAndRemovesAutostartEntry()
    {
        StartupManager manager;
        QVERIFY(!manager.enabled());
        QVERIFY(manager.promptRequired());
        manager.declineStartupPrompt();
        QVERIFY(!manager.promptRequired());
        QVERIFY(manager.setEnabled(true));
        QVERIFY(manager.enabled());

        const QString path = QStandardPaths::writableLocation(QStandardPaths::ConfigLocation)
                             + QStringLiteral("/autostart/%1.desktop")
                                   .arg(QString::fromUtf8(Imboard::AppId));
        QFile file(path);
        QVERIFY(file.open(QIODevice::ReadOnly));
        const QByteArray contents = file.readAll();
        QVERIFY(contents.contains("--start-hidden"));
        QVERIFY(contents.contains("Icon=io.github.anicetuscer.imboard"));
        QVERIFY(contents.contains("X-Imboard-Managed=true"));

        QVERIFY(manager.setEnabled(false));
        QVERIFY(!manager.enabled());
        QVERIFY(manager.error().isEmpty());
    }
};

QTEST_GUILESS_MAIN(StartupManagerTest)

#include "startupmanager_test.moc"
