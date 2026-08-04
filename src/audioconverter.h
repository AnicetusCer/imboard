// SPDX-FileCopyrightText: 2026 AnicetusCer
// SPDX-License-Identifier: GPL-3.0-or-later

#pragma once

#include <QAudioFormat>
#include <QByteArray>
#include <QVector>

namespace AudioConverter
{
// Converts interleaved native-endian Qt audio into the mono 16 kHz float PCM
// expected by whisper.cpp. Invalid or unsupported formats return an empty list.
[[nodiscard]] QVector<float> toWhisperPcm(const QByteArray &bytes,
                                          const QAudioFormat &format);
}
