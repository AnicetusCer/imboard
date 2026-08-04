// SPDX-FileCopyrightText: 2026 AnicetusCer
// SPDX-License-Identifier: GPL-3.0-or-later

#include "speechcontroller.h"

#include "audioconverter.h"

#include <QAudioDevice>
#include <QAudioSource>
#include <QFile>
#include <QFileInfo>
#include <QMediaDevices>
#include <QThread>
#include <QtConcurrentRun>

#include <algorithm>
#include <utility>

#ifdef IMBOARD_HAVE_WHISPER
#include <whisper.h>
#endif

namespace
{
constexpr int maximumRecordingMilliseconds = 60000;
constexpr int minimumWhisperSamples = 4800;
}

SpeechController::SpeechController(QObject *parent)
    : QObject(parent)
{
    m_audioBuffer.setBuffer(&m_recordedAudio);
    m_recordingLimit.setSingleShot(true);
    m_recordingLimit.setInterval(maximumRecordingMilliseconds);
    connect(&m_recordingLimit, &QTimer::timeout,
            this, &SpeechController::stopAndTranscribe);
    m_countdownTimer.setInterval(1000);
    connect(&m_countdownTimer, &QTimer::timeout,
            this, &SpeechController::countdownChanged);
    connect(&m_watcher, &QFutureWatcher<TranscriptionResult>::finished, this, [this]() {
        const TranscriptionResult result = m_watcher.result();
        if (m_runningGeneration != m_generation || result.cancelled) return;
        if (!result.error.isEmpty()) {
            setError(result.error);
            return;
        }
        m_transcript = result.text;
        setPhase(Phase::Ready,
                 m_transcript.isEmpty()
                     ? QStringLiteral("No speech was recognised. You can record again.")
                     : QStringLiteral("Review the text, make any changes, then apply it."));
        // Publish the transcript after the ready state so QML can immediately
        // place the edit cursor and scroll it into view.
        emit transcriptChanged();
    });

    m_status = available()
                   ? QStringLiteral("Ready to record locally with Whisper small.en.")
                   : QStringLiteral("The offline speech model is not installed in this build.");
}

SpeechController::~SpeechController()
{
    ++m_generation;
    m_cancelRequested.store(true);
    stopAudioCapture();
    if (m_watcher.isRunning()) m_watcher.waitForFinished();
}

QString SpeechController::phase() const
{
    switch (m_phase) {
    case Phase::Idle: return QStringLiteral("idle");
    case Phase::Recording: return QStringLiteral("recording");
    case Phase::Transcribing: return QStringLiteral("transcribing");
    case Phase::Ready: return QStringLiteral("ready");
    case Phase::Error: return QStringLiteral("error");
    }
    return QStringLiteral("error");
}

QString SpeechController::status() const
{
    return m_status;
}

QString SpeechController::transcript() const
{
    return m_transcript;
}

bool SpeechController::available() const
{
#ifdef IMBOARD_HAVE_WHISPER
    const QFileInfo model(modelPath());
    return model.isFile() && model.isReadable() && model.size() > 0;
#else
    return false;
#endif
}

bool SpeechController::recording() const noexcept
{
    return m_phase == Phase::Recording;
}

int SpeechController::recordingSecondsRemaining() const noexcept
{
    if (!recording()) return 0;
    const int remaining = m_recordingLimit.remainingTime();
    return remaining < 0 ? 0 : (remaining + 999) / 1000;
}

bool SpeechController::transcribing() const noexcept
{
    return m_phase == Phase::Transcribing;
}

bool SpeechController::startRecording()
{
    if (m_watcher.isRunning()) {
        setError(QStringLiteral("The previous transcription is still stopping. Please wait."));
        return false;
    }
    if (!available()) {
        setError(QStringLiteral("The offline Whisper small.en model is unavailable."));
        return false;
    }

    const QAudioDevice device = QMediaDevices::defaultAudioInput();
    if (device.isNull()) {
        setError(QStringLiteral("No microphone is available."));
        return false;
    }
    QAudioFormat format;
    format.setSampleRate(16000);
    format.setChannelCount(1);
    format.setSampleFormat(QAudioFormat::Float);
    if (!device.isFormatSupported(format)) format = device.preferredFormat();
    if (!format.isValid() || format.channelCount() < 1 || format.sampleRate() < 1
        || format.sampleFormat() == QAudioFormat::Unknown) {
        setError(QStringLiteral("The microphone reported an unsupported audio format."));
        return false;
    }

    ++m_generation;
    m_cancelRequested.store(false);
    m_recordedAudio.clear();
    m_captureFormat = format;
    if (!m_audioBuffer.open(QIODevice::WriteOnly | QIODevice::Truncate)) {
        setError(QStringLiteral("Could not prepare the private recording buffer."));
        return false;
    }
    m_audioSource = std::make_unique<QAudioSource>(device, format, this);
    connect(m_audioSource.get(), &QAudioSource::stateChanged, this,
            [this](QAudio::State state) {
        if (state != QAudio::StoppedState || !recording() || m_stoppingAudio) return;
        // QAudioSource may emit stateChanged synchronously from start(). Do not
        // destroy the source while one of its own methods is still on-stack.
        QTimer::singleShot(0, this, [this]() {
            if (!recording() || m_stoppingAudio || !m_audioSource
                || m_audioSource->error() == QAudio::NoError) return;
            stopAudioCapture();
            setError(QStringLiteral("Microphone recording stopped unexpectedly."));
        });
    });
    m_audioSource->start(&m_audioBuffer);
    if (m_audioSource->error() != QAudio::NoError) {
        stopAudioCapture();
        setError(QStringLiteral("Could not start microphone recording."));
        return false;
    }

    setPhase(Phase::Recording,
             QStringLiteral("Recording locally… Press STOP & TRANSCRIBE when finished."));
    m_recordingLimit.start();
    m_countdownTimer.start();
    emit countdownChanged();
    return true;
}

void SpeechController::stopAndTranscribe()
{
    if (!recording()) return;
    stopAudioCapture();

    setPhase(Phase::Transcribing,
             QStringLiteral("Transcribing privately on this device…"));
    m_runningGeneration = m_generation;
    QByteArray recordedAudio = std::move(m_recordedAudio);
    m_recordedAudio.clear();
    const QAudioFormat captureFormat = m_captureFormat;
    const QString path = modelPath();
    m_watcher.setFuture(QtConcurrent::run(
        [audio = std::move(recordedAudio), captureFormat, path,
         cancel = &m_cancelRequested]() mutable {
            if (cancel->load()) {
                TranscriptionResult result;
                result.cancelled = true;
                return result;
            }
            const QVector<float> samples =
                AudioConverter::toWhisperPcm(audio, captureFormat);
            audio = QByteArray();
            if (samples.size() < minimumWhisperSamples) {
                TranscriptionResult result;
                result.error = QStringLiteral(
                    "The recording was too short. Please record for a little longer.");
                return result;
            }
            return transcribe(samples, path, cancel);
        }));
}

void SpeechController::cancel()
{
    ++m_generation;
    m_cancelRequested.store(true);
    stopAudioCapture();
    m_recordedAudio.clear();
    m_transcript.clear();
    emit transcriptChanged();
    setPhase(Phase::Idle,
             available() ? QStringLiteral("Ready to record locally with Whisper small.en.")
                         : QStringLiteral("The offline speech model is not installed in this build."));
}

void SpeechController::clearTranscript()
{
    if (m_transcript.isEmpty()) return;
    m_transcript.clear();
    emit transcriptChanged();
}

bool SpeechController::applyTranscript(const QString &text)
{
    if (recording() || transcribing() || text.trimmed().isEmpty()) return false;
    emit textApplicationRequested(text);
    cancel();
    return true;
}

QString SpeechController::modelPath()
{
#ifdef IMBOARD_DEFAULT_SPEECH_MODEL
    return QString::fromUtf8(IMBOARD_DEFAULT_SPEECH_MODEL);
#else
    return {};
#endif
}

SpeechController::TranscriptionResult SpeechController::transcribe(
    const QVector<float> &samples, const QString &path, std::atomic_bool *cancelRequested)
{
    TranscriptionResult result;
    if (cancelRequested->load()) {
        result.cancelled = true;
        return result;
    }
#ifdef IMBOARD_HAVE_WHISPER
    whisper_context_params contextParameters = whisper_context_default_params();
    // Vulkan builds use the Deck's GPU; whisper.cpp retains its CPU backend as
    // a fallback on systems without a usable Vulkan compute device.
    contextParameters.use_gpu = true;
    const QByteArray encodedPath = QFile::encodeName(path);
    whisper_context *context =
        whisper_init_from_file_with_params(encodedPath.constData(), contextParameters);
    if (!context) {
        result.error = QStringLiteral("Whisper could not load the small.en model.");
        return result;
    }

    whisper_full_params parameters = whisper_full_default_params(WHISPER_SAMPLING_GREEDY);
    parameters.language = "en";
    parameters.translate = false;
    parameters.no_context = true;
    parameters.print_progress = false;
    parameters.print_realtime = false;
    parameters.print_timestamps = false;
    parameters.print_special = false;
    parameters.n_threads = std::clamp(QThread::idealThreadCount() - 1, 1, 4);
    parameters.abort_callback = [](void *data) {
        return static_cast<std::atomic_bool *>(data)->load();
    };
    parameters.abort_callback_user_data = cancelRequested;

    const int returnCode = whisper_full(context, parameters,
                                        samples.constData(), samples.size());
    if (cancelRequested->load()) {
        result.cancelled = true;
    } else if (returnCode != 0) {
        result.error = QStringLiteral("Local speech transcription failed.");
    } else {
        const int segmentCount = whisper_full_n_segments(context);
        for (int segment = 0; segment < segmentCount; ++segment)
            result.text.append(QString::fromUtf8(whisper_full_get_segment_text(context, segment)));
        result.text = result.text.trimmed();
    }
    whisper_free(context);
#else
    Q_UNUSED(samples)
    Q_UNUSED(path)
    result.error = QStringLiteral("This Imboard build has no offline speech engine.");
#endif
    return result;
}

void SpeechController::setError(const QString &message)
{
    setPhase(Phase::Error, message);
}

void SpeechController::setPhase(Phase phase, const QString &status)
{
    m_phase = phase;
    m_status = status;
    emit stateChanged();
}

void SpeechController::stopAudioCapture()
{
    if (m_stoppingAudio) return;
    m_stoppingAudio = true;
    m_countdownTimer.stop();
    m_recordingLimit.stop();
    emit countdownChanged();
    if (m_audioSource) {
        m_audioSource->stop();
        m_audioSource.reset();
    }
    if (m_audioBuffer.isOpen()) m_audioBuffer.close();
    m_stoppingAudio = false;
}
