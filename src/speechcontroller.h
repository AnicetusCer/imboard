// SPDX-FileCopyrightText: 2026 AnicetusCer
// SPDX-License-Identifier: GPL-3.0-or-later

#pragma once

#include <QAudioFormat>
#include <QBuffer>
#include <QFutureWatcher>
#include <QObject>
#include <QString>
#include <QTimer>
#include <QVector>

#include <atomic>
#include <memory>

class QAudioSource;

class SpeechController final : public QObject
{
    Q_OBJECT
    Q_PROPERTY(QString phase READ phase NOTIFY stateChanged)
    Q_PROPERTY(QString status READ status NOTIFY stateChanged)
    Q_PROPERTY(QString transcript READ transcript NOTIFY transcriptChanged)
    Q_PROPERTY(bool available READ available CONSTANT)
    Q_PROPERTY(bool recording READ recording NOTIFY stateChanged)
    Q_PROPERTY(int recordingSecondsRemaining READ recordingSecondsRemaining
               NOTIFY countdownChanged)
    Q_PROPERTY(bool transcribing READ transcribing NOTIFY stateChanged)

public:
    explicit SpeechController(QObject *parent = nullptr);
    ~SpeechController() override;

    [[nodiscard]] QString phase() const;
    [[nodiscard]] QString status() const;
    [[nodiscard]] QString transcript() const;
    [[nodiscard]] bool available() const;
    [[nodiscard]] bool recording() const noexcept;
    [[nodiscard]] int recordingSecondsRemaining() const noexcept;
    [[nodiscard]] bool transcribing() const noexcept;

    Q_INVOKABLE bool startRecording();
    Q_INVOKABLE void stopAndTranscribe();
    Q_INVOKABLE void cancel();
    Q_INVOKABLE void clearTranscript();

signals:
    void stateChanged();
    void countdownChanged();
    void transcriptChanged();

private:
    friend class SpeechControllerTest;

    enum class Phase { Idle, Recording, Transcribing, Ready, Error };
    struct TranscriptionResult {
        QString text;
        QString error;
        bool cancelled = false;
    };

    static QString modelPath();
    static bool isSafeCaptureFormat(const QAudioFormat &format);
    static TranscriptionResult transcribe(const QVector<float> &samples,
                                          const QString &modelPath,
                                          std::atomic_bool *cancelRequested);
    void setError(const QString &message);
    void setPhase(Phase phase, const QString &status);
    void stopAudioCapture();

    static constexpr qint64 MaximumRecordingBytes = 64 * 1024 * 1024;

    Phase m_phase = Phase::Idle;
    QString m_status;
    QString m_transcript;
    QByteArray m_recordedAudio;
    QBuffer m_audioBuffer;
    QAudioFormat m_captureFormat;
    std::unique_ptr<QAudioSource> m_audioSource;
    QTimer m_countdownTimer;
    QTimer m_recordingLimit;
    QFutureWatcher<TranscriptionResult> m_watcher;
    std::atomic_bool m_cancelRequested{false};
    quint64 m_generation = 0;
    quint64 m_runningGeneration = 0;
    bool m_stoppingAudio = false;
};
