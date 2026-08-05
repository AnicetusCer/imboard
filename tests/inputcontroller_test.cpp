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

        QVERIFY(!controller.sendText(QStringLiteral("private-token")));

        QCOMPARE(requests.count(), 1);
        const QString description = requests.takeFirst().at(0).toString();
        QVERIFY(description.startsWith(QStringLiteral("text:")));
        QVERIFY(!description.contains(QStringLiteral("private-token")));
    }

    void rejectsUnsupportedTextControlCharactersBeforeInput()
    {
        InputController controller;
        QSignalSpy requests(&controller, &InputController::actionRequested);

        QTest::ignoreMessage(QtWarningMsg,
                             "Rejected text containing an unsupported control character");
        QVERIFY(!controller.sendText(QString::fromLatin1("safe\x01unsafe")));

        QCOMPARE(requests.count(), 1);
        QVERIFY(!controller.backendReady());
    }

    void localEditingInterceptsActionsBeforePortalInput()
    {
        InputController controller;
        QSignalSpy textRequests(&controller, &InputController::localTextRequested);
        QSignalSpy keyRequests(&controller, &InputController::localKeyRequested);
        QSignalSpy chordRequests(&controller, &InputController::localChordRequested);

        controller.setLocalTextEditing(true);
        QVERIFY(controller.sendText(QStringLiteral("correction")));
        controller.sendKey(QStringLiteral("Backspace"));
        controller.sendChord({QStringLiteral("Ctrl")}, QStringLiteral("A"));

        QCOMPARE(textRequests.count(), 1);
        QCOMPARE(textRequests.takeFirst().at(0).toString(), QStringLiteral("correction"));
        QCOMPARE(keyRequests.count(), 1);
        QCOMPARE(keyRequests.takeFirst().at(0).toString(), QStringLiteral("Backspace"));
        QCOMPARE(chordRequests.count(), 1);
        QVERIFY(controller.localTextEditing());
        QVERIFY(!controller.backendReady());
    }

    void textDeliveryValidationMatchesUnicodePolicy()
    {
        InputController controller;
        controller.setExperimentalUnicodeEnabled(false);

        QVERIFY(controller.canSendText(QStringLiteral("ASCII text\nwith a tab\t")));
        QVERIFY(!controller.canSendText(QString::fromLatin1("unsafe\x01control")));
        QVERIFY(!controller.canSendText(QString::fromUtf8("cost £5")));

        controller.setExperimentalUnicodeEnabled(true);
        QVERIFY(controller.canSendText(QString::fromUtf8("cost £5")));
        QVERIFY(!controller.canSendText(QString::fromLatin1("unsafe\x01control")));
        controller.setExperimentalUnicodeEnabled(false);
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
