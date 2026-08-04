// SPDX-FileCopyrightText: 2026 AnicetusCer
// SPDX-License-Identifier: GPL-3.0-or-later

#include "audioconverter.h"

#include <QTest>

#include <cmath>
#include <cstring>
#include <limits>

namespace
{
void appendInt16(QByteArray &bytes, qint16 value)
{
    const qsizetype offset = bytes.size();
    bytes.resize(offset + static_cast<qsizetype>(sizeof(value)));
    std::memcpy(bytes.data() + offset, &value, sizeof(value));
}

QAudioFormat int16Format(int rate, int channels)
{
    QAudioFormat format;
    format.setSampleRate(rate);
    format.setChannelCount(channels);
    format.setSampleFormat(QAudioFormat::Int16);
    return format;
}
}

class AudioConverterTest final : public QObject
{
    Q_OBJECT

private slots:
    void preservesMono16k();
    void mixesStereoChannels();
    void resamples48kTo16k();
    void sanitizesInvalidFloatSamples();
    void rejectsInvalidFormat();
};

void AudioConverterTest::preservesMono16k()
{
    QByteArray bytes;
    appendInt16(bytes, 0);
    appendInt16(bytes, 16384);
    appendInt16(bytes, -16384);

    const QVector<float> samples =
        AudioConverter::toWhisperPcm(bytes, int16Format(16000, 1));
    QCOMPARE(samples.size(), 3);
    QVERIFY(std::abs(samples.at(0)) < 0.0001F);
    QVERIFY(std::abs(samples.at(1) - 0.5F) < 0.0001F);
    QVERIFY(std::abs(samples.at(2) + 0.5F) < 0.0001F);
}

void AudioConverterTest::mixesStereoChannels()
{
    QByteArray bytes;
    appendInt16(bytes, 16384);
    appendInt16(bytes, -16384);
    appendInt16(bytes, 16384);
    appendInt16(bytes, 16384);

    const QVector<float> samples =
        AudioConverter::toWhisperPcm(bytes, int16Format(16000, 2));
    QCOMPARE(samples.size(), 2);
    QVERIFY(std::abs(samples.at(0)) < 0.0001F);
    QVERIFY(std::abs(samples.at(1) - 0.5F) < 0.0001F);
}

void AudioConverterTest::resamples48kTo16k()
{
    QByteArray bytes;
    for (int index = 0; index < 480; ++index)
        appendInt16(bytes, static_cast<qint16>(index * 20));

    const QVector<float> samples =
        AudioConverter::toWhisperPcm(bytes, int16Format(48000, 1));
    QCOMPARE(samples.size(), 160);
    QVERIFY(samples.first() <= samples.last());
}

void AudioConverterTest::sanitizesInvalidFloatSamples()
{
    QAudioFormat format;
    format.setSampleRate(16000);
    format.setChannelCount(1);
    format.setSampleFormat(QAudioFormat::Float);

    const float values[]{std::numeric_limits<float>::quiet_NaN(),
                         std::numeric_limits<float>::infinity(), 2.0F};
    QByteArray bytes(reinterpret_cast<const char *>(values), sizeof(values));
    const QVector<float> samples = AudioConverter::toWhisperPcm(bytes, format);

    QCOMPARE(samples.size(), 3);
    QCOMPARE(samples.at(0), 0.0F);
    QCOMPARE(samples.at(1), 0.0F);
    QCOMPARE(samples.at(2), 1.0F);
}

void AudioConverterTest::rejectsInvalidFormat()
{
    QAudioFormat invalid;
    QVERIFY(AudioConverter::toWhisperPcm(QByteArray(16, '\0'), invalid).isEmpty());
}

QTEST_GUILESS_MAIN(AudioConverterTest)

#include "audioconverter_test.moc"
