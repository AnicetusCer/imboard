// SPDX-FileCopyrightText: 2026 AnicetusCer
// SPDX-License-Identifier: GPL-3.0-or-later

#include "surfacecontroller.h"

#include <QDebug>
#include <QGuiApplication>
#include <QQuickWindow>
#include <QRegion>
#include <QScreen>
#include <QSettings>
#include <QWindow>

#ifdef IMBOARD_HAVE_LAYER_SHELL
#include <LayerShellQt/Window>
#endif

SurfaceController::SurfaceController(QObject *parent)
    : QObject(parent)
{
    m_frameTimer.setSingleShot(true);
    m_frameTimer.setInterval(80);
    connect(&m_frameTimer, &QTimer::timeout, this, [this]() {
        if (m_sizePending) {
            m_sizePending = false;
            applySize(m_pendingSize);
        }
    });
}

bool SurfaceController::layerShellActive() const noexcept
{
    return m_layerShellActive;
}

bool SurfaceController::previewVisible() const noexcept
{
    return m_previewVisible;
}

QPoint SurfaceController::previewPosition() const noexcept
{
    return m_pendingPosition;
}

QSize SurfaceController::previewSize() const noexcept
{
    return m_window ? m_window->size() : QSize();
}

void SurfaceController::configure(QWindow *window, QWindow *previewWindow)
{
    m_window = window;
    m_previewWindow = previewWindow;
    if (!m_window) return;

#ifdef IMBOARD_HAVE_LAYER_SHELL
    m_layerShellActive = QGuiApplication::platformName() == QStringLiteral("wayland");
    if (m_layerShellActive) {
        auto *surface = LayerShellQt::Window::get(m_window);
        surface->setScope(QStringLiteral("imboard"));
        surface->setLayer(LayerShellQt::Window::LayerOverlay);
        surface->setKeyboardInteractivity(
            LayerShellQt::Window::KeyboardInteractivityNone);
        surface->setActivateOnShow(false);
        surface->setExclusiveZone(-1);
        surface->setAnchors(
            LayerShellQt::Window::Anchors(LayerShellQt::Window::AnchorTop)
            | LayerShellQt::Window::AnchorLeft);
        surface->setDesiredSize(m_window->size());

        const QRect area = m_window->screen()->availableGeometry();
        QSettings settings;
        const QPoint defaultPosition(
            qMax(0, (area.width() - m_window->width()) / 2),
            qMax(0, area.height() - m_window->height() - 24));
        m_position = settings.value(QStringLiteral("window/layerPosition"),
                                    defaultPosition).toPoint();
        applyPosition(m_position);

        connect(m_window, &QWindow::widthChanged, this, [this]() {
            if (m_window) applySize(m_window->size());
        });
        connect(m_window, &QWindow::heightChanged, this, [this]() {
            if (m_window) applySize(m_window->size());
        });

        if (m_previewWindow) {
            auto *previewSurface = LayerShellQt::Window::get(m_previewWindow);
            previewSurface->setScope(QStringLiteral("imboard-drag-preview"));
            previewSurface->setLayer(LayerShellQt::Window::LayerOverlay);
            previewSurface->setKeyboardInteractivity(
                LayerShellQt::Window::KeyboardInteractivityNone);
            previewSurface->setActivateOnShow(false);
            previewSurface->setExclusiveZone(-1);
            previewSurface->setAnchors(
                LayerShellQt::Window::Anchors(LayerShellQt::Window::AnchorTop)
                | LayerShellQt::Window::AnchorBottom
                | LayerShellQt::Window::AnchorLeft
                | LayerShellQt::Window::AnchorRight);
            previewSurface->setDesiredSize(QSize(0, 0));
            m_previewWindow->setMask(QRegion());
        }
    }
#endif
}

void SurfaceController::beginMove(const QPointF &globalPosition)
{
    if (!m_window) return;
    if (!m_layerShellActive) {
        if (!m_window->startSystemMove())
            qWarning() << "The window manager rejected the Imboard move request";
        return;
    }
    m_pointerOrigin = globalPosition;
    m_positionOrigin = m_position;
    m_pendingPosition = m_position;
    m_interaction = Interaction::Move;
    setPreviewVisible(true);
}

void SurfaceController::updateMove(const QPointF &globalPosition)
{
    if (!m_window || !m_layerShellActive) return;
    const QPoint delta = (globalPosition - m_pointerOrigin).toPoint();
    const QPoint nextPosition = boundedPosition(m_positionOrigin + delta);
    if (m_pendingPosition == nextPosition) return;
    m_pendingPosition = nextPosition;
    emit previewChanged();
}

void SurfaceController::beginResize(const QPointF &globalPosition)
{
    if (!m_window) return;
    if (!m_layerShellActive) {
        if (!m_window->startSystemResize(Qt::RightEdge | Qt::BottomEdge))
            qWarning() << "The window manager rejected the Imboard resize request";
        return;
    }
    m_pointerOrigin = globalPosition;
    m_sizeOrigin = m_window->size();
    m_interaction = Interaction::Resize;
}

void SurfaceController::updateResize(const QPointF &globalPosition)
{
    if (!m_window || !m_layerShellActive) return;
    const QPoint delta = (globalPosition - m_pointerOrigin).toPoint();
    m_pendingSize = QSize(m_sizeOrigin.width() + delta.x(),
                          m_sizeOrigin.height() + delta.y());
    m_sizePending = true;
    if (!m_frameTimer.isActive()) {
        m_sizePending = false;
        applySize(m_pendingSize);
        m_frameTimer.start();
    }
}

void SurfaceController::finishInteraction()
{
    if (!m_window || !m_layerShellActive) return;
    if (m_interaction == Interaction::Move) {
        setPreviewVisible(false);
        applyPosition(m_pendingPosition);
        m_interaction = Interaction::None;
        QSettings settings;
        settings.setValue(QStringLiteral("window/layerPosition"), m_position);
        settings.sync();
        if (settings.status() != QSettings::NoError)
            qWarning() << "Could not save the Imboard window position";
        return;
    }

    m_frameTimer.stop();
    if (m_sizePending) {
        m_sizePending = false;
        applySize(m_pendingSize);
    }
    QSettings settings;
    settings.setValue(QStringLiteral("window/layerPosition"), m_position);
    settings.setValue(QStringLiteral("window/size"), m_window->size());
    settings.sync();
    if (settings.status() != QSettings::NoError)
        qWarning() << "Could not save the Imboard window geometry";
    m_interaction = Interaction::None;
}

void SurfaceController::hideWindow()
{
    if (m_window) m_window->hide();
}

QPoint SurfaceController::boundedPosition(const QPoint &position) const
{
    if (!m_window) return position;
    const QRect area = m_window->screen()->availableGeometry();
    return QPoint(qBound(0, position.x(), qMax(0, area.width() - m_window->width())),
                  qBound(0, position.y(), qMax(0, area.height() - m_window->height())));
}

void SurfaceController::setPreviewVisible(bool visible)
{
    if (!m_previewWindow || m_previewVisible == visible) return;
    m_previewVisible = visible;
    if (visible) {
        m_previewWindow->show();
    } else {
        m_previewWindow->hide();
    }
    emit previewChanged();
}

void SurfaceController::applyPosition(const QPoint &position)
{
    if (!m_window || !m_layerShellActive) return;
    m_position = boundedPosition(position);
#ifdef IMBOARD_HAVE_LAYER_SHELL
    LayerShellQt::Window::get(m_window)->setMargins(
        QMargins(m_position.x(), m_position.y(), 0, 0));
#endif
    if (auto *quickWindow = qobject_cast<QQuickWindow *>(m_window)) {
        quickWindow->update();
        QTimer::singleShot(0, quickWindow, [quickWindow]() {
            quickWindow->update();
        });
    } else {
        m_window->requestUpdate();
    }
}

void SurfaceController::applySize(const QSize &size)
{
    if (!m_window) return;
    const QSize maximum = m_window->screen()->availableGeometry().size();
    const QSize bounded = size.expandedTo(m_window->minimumSize()).boundedTo(maximum);
    if (m_window->size() != bounded) m_window->resize(bounded);
#ifdef IMBOARD_HAVE_LAYER_SHELL
    if (m_layerShellActive)
        LayerShellQt::Window::get(m_window)->setDesiredSize(bounded);
#endif
    if (m_layerShellActive) applyPosition(m_position);
}
