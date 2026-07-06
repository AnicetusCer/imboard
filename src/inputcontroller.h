// SPDX-FileCopyrightText: 2026 AnicetusCer
// SPDX-License-Identifier: GPL-3.0-or-later

#pragma once

#include <QObject>
#include <QString>
#include <QStringList>

#include "portalinputbackend.h"

class InputController final : public QObject
{
    Q_OBJECT
    Q_PROPERTY(bool backendReady READ backendReady NOTIFY backendReadyChanged)
    Q_PROPERTY(QString backendStatus READ backendStatus NOTIFY backendReadyChanged)
    Q_PROPERTY(bool setupRequired READ setupRequired NOTIFY backendReadyChanged)
    Q_PROPERTY(bool experimentalUnicodeEnabled READ experimentalUnicodeEnabled
                   WRITE setExperimentalUnicodeEnabled
                   NOTIFY experimentalUnicodeEnabledChanged)

public:
    explicit InputController(QObject *parent = nullptr);

    [[nodiscard]] bool backendReady() const noexcept;
    [[nodiscard]] QString backendStatus() const;
    [[nodiscard]] bool setupRequired() const;
    [[nodiscard]] bool experimentalUnicodeEnabled() const noexcept;
    void setExperimentalUnicodeEnabled(bool enabled);

    Q_INVOKABLE void connectPortal();
    Q_INVOKABLE void disconnectPortal();
    Q_INVOKABLE void restorePortalIfConfigured();
    Q_INVOKABLE bool forgetPortalPermission();

    Q_INVOKABLE void sendText(const QString &text);
    Q_INVOKABLE void sendKey(const QString &key);
    Q_INVOKABLE void sendChord(const QStringList &modifiers, const QString &key);

signals:
    void backendReadyChanged();
    void experimentalUnicodeEnabledChanged();
    void actionRequested(const QString &description);

private:
    bool pasteTextViaClipboard(const QString &text);
    static quint32 namedKeysym(const QString &key);
    static QString normalizedChordKey(const QStringList &modifiers, const QString &key);
    PortalInputBackend m_portal;
    bool m_experimentalUnicodeEnabled = false;
};
