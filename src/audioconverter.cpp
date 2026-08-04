// SPDX-FileCopyrightText: 2026 AnicetusCer
// SPDX-License-Identifier: GPL-3.0-or-later

#include "audioconverter.h"

#include <QtGlobal>

#include <algorithm>
#include <cmath>
#include <cstring>
#include <limits>

namespace
{
float sampleAt(const char *data, QAudioFormat::SampleFormat format)
{
    switch (format) {
    case QAudioFormat::UInt8: {
        quint8 value = 0;
        std::memcpy(&value, data, sizeof(value));
        return (static_cast<float>(value) - 128.0F) / 128.0F;
    }
    case QAudioFormat::Int16: {
        qint16 value = 0;
        std::memcpy(&value, data, sizeof(value));
        return static_cast<float>(value) / 32768.0F;
    }
    case QAudioFormat::Int32: {
        qint32 value = 0;
        std::memcpy(&value, data, sizeof(value));
        return static_cast<float>(static_cast<double>(value) / 2147483648.0);
    }
    case QAudioFormat::Float: {
        float value = 0.0F;
        std::memcpy(&value, data, sizeof(value));
        return std::isfinite(value) ? std::clamp(value, -1.0F, 1.0F) : 0.0F;
    }
    case QAudioFormat::Unknown:
    case QAudioFormat::NSampleFormats:
        break;
    }
    return 0.0F;
}
}

namespace AudioConverter
{
QVector<float> toWhisperPcm(const QByteArray &bytes, const QAudioFormat &format)
{
    constexpr int targetRate = 16000;
    const int channelCount = format.channelCount();
    const int sampleRate = format.sampleRate();
    const int bytesPerSample = format.bytesPerSample();
    const int bytesPerFrame = format.bytesPerFrame();
    if (!format.isValid() || channelCount < 1 || sampleRate < 1
        || bytesPerSample < 1 || bytesPerFrame != channelCount * bytesPerSample
        || format.sampleFormat() == QAudioFormat::Unknown) {
        return {};
    }

    const qsizetype frameCount = bytes.size() / bytesPerFrame;
    if (frameCount < 1) return {};

    QVector<float> mono;
    mono.reserve(frameCount);
    const char *raw = bytes.constData();
    for (qsizetype frame = 0; frame < frameCount; ++frame) {
        double sum = 0.0;
        const char *frameData = raw + frame * bytesPerFrame;
        for (int channel = 0; channel < channelCount; ++channel)
            sum += sampleAt(frameData + channel * bytesPerSample, format.sampleFormat());
        mono.append(static_cast<float>(sum / channelCount));
    }

    if (sampleRate == targetRate) return mono;

    const qsizetype outputCount = static_cast<qsizetype>(
        std::floor(static_cast<double>(mono.size()) * targetRate / sampleRate));
    if (outputCount < 1) return {};

    QVector<float> resampled;
    resampled.reserve(outputCount);
    for (qsizetype outputIndex = 0; outputIndex < outputCount; ++outputIndex) {
        const double sourcePosition = static_cast<double>(outputIndex) * sampleRate / targetRate;
        const qsizetype lowerIndex = static_cast<qsizetype>(sourcePosition);
        const qsizetype upperIndex = std::min(lowerIndex + 1, mono.size() - 1);
        const float fraction = static_cast<float>(sourcePosition - lowerIndex);
        resampled.append(mono.at(lowerIndex) * (1.0F - fraction)
                         + mono.at(upperIndex) * fraction);
    }
    return resampled;
}
}
