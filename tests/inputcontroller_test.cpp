// SPDX-FileCopyrightText: 2026 AnicetusCer
// SPDX-License-Identifier: GPL-3.0-or-later

#include "inputcontroller.h"

#include <QSignalSpy>
#include <QSettings>
#include <QTest>

class InputControllerTest final : public QObject
{
    Q_OBJECT

private slots:
    void initTestCase()
    {
        QCoreApplication::setOrganizationName(QStringLiteral("ImboardTests"));
        QCoreApplication::setApplicationName(QStringLiteral("InputController"));
        QSettings().clear();
    }

    void rejectsInvalidKeysAndChords()
    {
        InputController controller;
        QSignalSpy requests(&controller, &InputController::actionRequested);

        QTest::ignoreMessage(QtWarningMsg, "Unsupported key: NotARealKey");
        controller.sendKey(QStringLiteral("NotARealKey"));

        QTest::ignoreMessage(QtWarningMsg, "Rejected a chord without modifiers");
        controller.sendChord({}, QStringLiteral("X"));

        QTest::ignoreMessage(QtWarningMsg, "Invalid chord modifier: Root");
        controller.sendChord({QStringLiteral("Root")}, QStringLiteral("X"));

        QTest::ignoreMessage(QtWarningMsg, "Invalid chord modifier: Ctrl");
        controller.sendChord({QStringLiteral("Ctrl"), QStringLiteral("Ctrl")},
                             QStringLiteral("X"));

        QCOMPARE(requests.count(), 4);
        QVERIFY(!controller.backendReady());
    }

    void textActionsDoNotExposePayloads()
    {
        InputController controller;
        QSignalSpy requests(&controller, &InputController::actionRequested);

        controller.sendText(QStringLiteral("private-token"));

        QCOMPARE(requests.count(), 1);
        const QString description = requests.takeFirst().at(0).toString();
        QVERIFY(description.startsWith(QStringLiteral("text:")));
        QVERIFY(!description.contains(QStringLiteral("private-token")));
    }

    void experimentalUnicodeSettingPersists()
    {
        InputController controller;
        QVERIFY(!controller.experimentalUnicodeEnabled());

        controller.setExperimentalUnicodeEnabled(true);
        QVERIFY(controller.experimentalUnicodeEnabled());

        InputController reloaded;
        QVERIFY(reloaded.experimentalUnicodeEnabled());
    }
};

QTEST_GUILESS_MAIN(InputControllerTest)

#include "inputcontroller_test.moc"
