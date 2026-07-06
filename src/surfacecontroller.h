// SPDX-FileCopyrightText: 2026 AnicetusCer
// SPDX-License-Identifier: GPL-3.0-or-later

#pragma once

#include <QObject>
#include <QPointF>
#include <QSize>
#include <QTimer>

class QWindow;

class SurfaceController final : public QObject
{
    Q_OBJECT
    Q_PROPERTY(bool layerShellActive READ layerShellActive CONSTANT)
    Q_PROPERTY(bool previewVisible READ previewVisible NOTIFY previewChanged)
    Q_PROPERTY(QPoint previewPosition READ previewPosition NOTIFY previewChanged)
    Q_PROPERTY(QSize previewSize READ previewSize NOTIFY previewChanged)

public:
    explicit SurfaceController(QObject *parent = nullptr);

    [[nodiscard]] bool layerShellActive() const noexcept;
    [[nodiscard]] bool previewVisible() const noexcept;
    [[nodiscard]] QPoint previewPosition() const noexcept;
    [[nodiscard]] QSize previewSize() const noexcept;
    void configure(QWindow *window, QWindow *previewWindow);

    Q_INVOKABLE void beginMove(const QPointF &globalPosition);
    Q_INVOKABLE void updateMove(const QPointF &globalPosition);
    Q_INVOKABLE void beginResize(const QPointF &globalPosition);
    Q_INVOKABLE void updateResize(const QPointF &globalPosition);
    Q_INVOKABLE void finishInteraction();
    Q_INVOKABLE void hideWindow();

signals:
    void previewChanged();

private:
    enum class Interaction { None, Move, Resize };
    QPoint boundedPosition(const QPoint &position) const;
    void setPreviewVisible(bool visible);
    void applyPosition(const QPoint &position);
    void applySize(const QSize &size);

    QWindow *m_window = nullptr;
    QWindow *m_previewWindow = nullptr;
    bool m_layerShellActive = false;
    bool m_previewVisible = false;
    QPointF m_pointerOrigin;
    QPoint m_positionOrigin;
    QSize m_sizeOrigin;
    QPoint m_position;
    QPoint m_pendingPosition;
    QSize m_pendingSize;
    bool m_sizePending = false;
    Interaction m_interaction = Interaction::None;
    QTimer m_frameTimer;
};
