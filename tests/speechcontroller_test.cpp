// SPDX-FileCopyrightText: 2026 AnicetusCer
// SPDX-License-Identifier: GPL-3.0-or-later

#include "speechcontroller.h"

#include <QSignalSpy>
#include <QTest>

class SpeechControllerTest final : public QObject
{
    Q_OBJECT

private slots:
    void acceptsBoundedCaptureFormats()
    {
        QAudioFormat format;
        format.setSampleRate(48000);
        format.setChannelCount(2);
        format.setSampleFormat(QAudioFormat::Float);
        QVERIFY(SpeechController::isSafeCaptureFormat(format));

        format.setSampleRate(192000);
        format.setChannelCount(8);
        QVERIFY(!SpeechController::isSafeCaptureFormat(format));

        format.setSampleRate(384000);
        format.setChannelCount(1);
        QVERIFY(!SpeechController::isSafeCaptureFormat(format));

        format.setSampleRate(48000);
        format.setChannelCount(0);
        QVERIFY(!SpeechController::isSafeCaptureFormat(format));
    }

    void reportsMissingModelAndRecoversToIdle()
    {
        SpeechController controller;
        QSignalSpy stateChanges(&controller, &SpeechController::stateChanged);

        QVERIFY(!controller.available());
        QCOMPARE(controller.phase(), QStringLiteral("idle"));
        QVERIFY(controller.status().contains(QStringLiteral("Install")));

        QVERIFY(!controller.startRecording());
        QCOMPARE(controller.phase(), QStringLiteral("error"));
        QVERIFY(controller.status().contains(QStringLiteral("model add-on")));
        QVERIFY(!controller.recording());
        QVERIFY(!controller.transcribing());

        controller.cancel();
        QCOMPARE(controller.phase(), QStringLiteral("idle"));
        QVERIFY(controller.status().contains(QStringLiteral("Install")));
        QVERIFY(stateChanges.count() >= 2);
    }
};

QTEST_GUILESS_MAIN(SpeechControllerTest)

#include "speechcontroller_test.moc"
