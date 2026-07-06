// SPDX-FileCopyrightText: 2026 AnicetusCer
// SPDX-License-Identifier: GPL-3.0-or-later

#pragma once

class AppearanceStore;
class QGuiApplication;
class QWindow;

namespace SmokeTestController
{
// Finds the QML test hooks and schedules the non-interactive UI checks.
// Returns false when the expected object tree is incomplete.
bool schedule(QGuiApplication &app, QWindow *window, AppearanceStore &appearance);
}
