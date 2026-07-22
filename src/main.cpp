// SPDX-FileCopyrightText: 2026 AnicetusCer
// SPDX-License-Identifier: GPL-3.0-or-later

#include "appearancestore.h"
#include "appmetadata.h"
#include "compatibilitystore.h"
#include "customkeystore.h"
#include "inputcontroller.h"
#include "instancecontroller.h"
#include "keyboardlayoutstore.h"
#include "signalhandler.h"
#include "smoketestcontroller.h"
#include "startupmanager.h"
#include "surfacecontroller.h"

#include <QDebug>
#include <QAction>
#include <QApplication>
#include <QIcon>
#include <QMenu>
#include <QQmlApplicationEngine>
#include <QQmlComponent>
#include <QScreen>
#include <QSettings>
#include <QSystemTrayIcon>
#include <QTimer>
#include <QUrl>
#include <QWindow>
#include <QtGlobal>

#ifdef IMBOARD_HAVE_LAYER_SHELL
#include <LayerShellQt/Shell>
#endif

int main(int argc, char *argv[])
{
    qputenv("QML_DISABLE_DISK_CACHE", "1");

#ifdef IMBOARD_HAVE_LAYER_SHELL
#if QT_VERSION < 0x060500
    if (qEnvironmentVariableIsSet("WAYLAND_DISPLAY"))
        LayerShellQt::Shell::useLayerShell();
#endif
#endif
    QApplication app(argc, argv);
    QApplication::setApplicationName(QString::fromUtf8(Imboard::AppName));
    QApplication::setOrganizationName(QString::fromUtf8(Imboard::OrganizationName));
    QApplication::setDesktopFileName(QString::fromUtf8(Imboard::AppId));
    QApplication::setQuitOnLastWindowClosed(false);

    const bool toggleLaunch = app.arguments().contains(QStringLiteral("--toggle"));
    const bool startHidden = app.arguments().contains(QStringLiteral("--start-hidden")) && !toggleLaunch;
    const bool smokeTest = app.arguments().contains(QStringLiteral("--smoke-test"));

    if (app.arguments().contains(QStringLiteral("--quit"))) {
        if (!InstanceController::sendCommand(QStringLiteral("QUIT"))) {
            qCritical() << "No running Imboard window responded";
            return 1;
        }
        return 0;
    }

    if (toggleLaunch && InstanceController::sendCommand(QStringLiteral("TOGGLE"))) {
        return 0;
    }

    InstanceController instance;
    if (!instance.start()) {
        if (InstanceController::sendCommand(QStringLiteral("SHOW"))) {
            qInfo() << "Imboard is already running";
            return 0;
        }
        qCritical().noquote() << "Could not start Imboard:" << instance.error();
        return 7;
    }

    SignalHandler signalHandler;
    if (!signalHandler.install()) {
        qCritical() << "Could not install termination-signal handler";
        return 2;
    }
    QObject::connect(&signalHandler, &SignalHandler::terminationRequested,
                     &app, &QCoreApplication::quit);

    InputController inputController;
    CustomKeyStore customKeys;
    AppearanceStore appearance;
    CompatibilityStore compatibility;
    KeyboardLayoutStore keyboardLayout;
    if (keyboardLayout.layoutId().isEmpty()) {
        qCritical() << "Imboard cannot start without a valid keyboard layout";
        return 8;
    }
    StartupManager startup;
    SurfaceController surface;
    QQmlApplicationEngine engine;
    QObject::connect(&engine, &QQmlApplicationEngine::quit,
                     &app, &QCoreApplication::quit);
    QQmlComponent component(&engine, QUrl(QStringLiteral("qrc:/Imboard/qml/Main.qml")));
    QObject *rootObject = component.createWithInitialProperties({
        {QStringLiteral("appearanceStore"), QVariant::fromValue(&appearance)},
        {QStringLiteral("compatibilityStore"), QVariant::fromValue(&compatibility)},
        {QStringLiteral("customKeyStore"), QVariant::fromValue(&customKeys)},
        {QStringLiteral("inputController"), QVariant::fromValue(&inputController)},
        {QStringLiteral("keyboardLayoutStore"), QVariant::fromValue(&keyboardLayout)},
        {QStringLiteral("startupManager"), QVariant::fromValue(&startup)},
        {QStringLiteral("surfaceController"), QVariant::fromValue(&surface)},
        {QStringLiteral("suppressInitialSetup"), smokeTest},
    });

    if (!rootObject) {
        qCritical().noquote() << "Could not load Imboard QML:" << component.errorString();
        return 3;
    }
    rootObject->setParent(&engine);

    auto *window = qobject_cast<QWindow *>(rootObject);
    if (!window) {
        qCritical() << "Imboard root object is not a window";
        return 4;
    }

    auto *previewWindow = window->findChild<QWindow *>(QStringLiteral("dragPreviewWindow"));
    if (!previewWindow) {
        qCritical() << "Imboard drag preview window is unavailable";
        return 5;
    }

    const Qt::WindowFlags requiredSurfaceFlags = Qt::Tool
                                                  | Qt::WindowStaysOnTopHint
                                                  | Qt::WindowDoesNotAcceptFocus;
    if ((window->flags() & requiredSurfaceFlags) != requiredSurfaceFlags) {
        qCritical() << "Imboard surface is missing required focus or stacking flags";
        return 6;
    }

    const auto windowSizeKey = [&appearance]() {
        return appearance.customPadOnlyEnabled()
                   ? QStringLiteral("window/customPadSize")
                   : QStringLiteral("window/fullSize");
    };
    const auto defaultWindowSize = [&appearance]() {
        return appearance.customPadOnlyEnabled() ? QSize(340, 220) : QSize(1120, 350);
    };
    const auto restoreWindowSize = [window, &windowSizeKey, &defaultWindowSize]() {
        QSettings settings;
        if (!settings.contains(QStringLiteral("window/fullSize"))
            && settings.contains(QStringLiteral("window/size"))) {
            settings.setValue(QStringLiteral("window/fullSize"),
                              settings.value(QStringLiteral("window/size")));
        }
        const QSize savedSize = settings.value(windowSizeKey(), defaultWindowSize()).toSize();
        const QSize maximumSize = window->screen()->availableGeometry().size();
        window->resize(savedSize.boundedTo(maximumSize).expandedTo(window->minimumSize()));
    };
    restoreWindowSize();
    surface.configure(window, previewWindow);

    QTimer sizeSaveTimer;
    sizeSaveTimer.setSingleShot(true);
    sizeSaveTimer.setInterval(250);
    QObject::connect(&sizeSaveTimer, &QTimer::timeout, window, [window, &windowSizeKey]() {
        if (window->property("customPadEditorMode").toBool()) {
            return;
        }
        QSettings settings;
        settings.setValue(windowSizeKey(), window->size());
        settings.sync();
        if (settings.status() != QSettings::NoError)
            qWarning() << "Could not save the Imboard window size";
    });
    QObject::connect(window, &QWindow::widthChanged, &sizeSaveTimer,
                     qOverload<>(&QTimer::start));
    QObject::connect(window, &QWindow::heightChanged, &sizeSaveTimer,
                     qOverload<>(&QTimer::start));
    bool customPadMode = appearance.customPadOnlyEnabled();
    QObject::connect(&appearance, &AppearanceStore::appearanceChanged, window,
                     [window, &appearance, &customPadMode, &restoreWindowSize]() {
        const bool nextCustomPadMode = appearance.customPadOnlyEnabled();
        QTimer::singleShot(0, window, [window, nextCustomPadMode,
                                       &customPadMode, &restoreWindowSize]() {
            if (customPadMode != nextCustomPadMode) {
                customPadMode = nextCustomPadMode;
                restoreWindowSize();
            } else if (window->size().expandedTo(window->minimumSize()) != window->size()) {
                window->resize(window->size().expandedTo(window->minimumSize()));
            }
        });
    });
    auto showKeyboard = [window, &surface]() {
        if (surface.layerShellActive()) window->show();
        else window->showNormal();
        window->raise();
    };
    auto hideKeyboard = [window, &surface]() {
        if (surface.layerShellActive()) window->hide();
        else window->showMinimized();
    };
    auto toggleKeyboard = [window, showKeyboard, hideKeyboard]() {
        if (!window->isVisible() || window->visibility() == QWindow::Minimized) {
            showKeyboard();
        } else {
            hideKeyboard();
        }
    };

    QObject::connect(&instance, &InstanceController::showRequested, window, showKeyboard);
    QObject::connect(&instance, &InstanceController::toggleRequested, window, toggleKeyboard);
    QObject::connect(&instance, &InstanceController::quitRequested,
                     &app, &QCoreApplication::quit);

    QMenu trayMenu;
    QAction showHideAction(QStringLiteral("Show / Hide Imboard"), &trayMenu);
    QAction quitAction(QStringLiteral("Quit Imboard"), &trayMenu);
    trayMenu.addAction(&showHideAction);
    trayMenu.addSeparator();
    trayMenu.addAction(&quitAction);

    QSystemTrayIcon trayIcon(QIcon::fromTheme(QString::fromUtf8(Imboard::AppId)), &app);
    trayIcon.setToolTip(QString::fromUtf8(Imboard::AppName));
    trayIcon.setContextMenu(&trayMenu);
    QObject::connect(&showHideAction, &QAction::triggered, window, toggleKeyboard);
    QObject::connect(&quitAction, &QAction::triggered, &app, &QCoreApplication::quit);
    QObject::connect(&trayIcon, &QSystemTrayIcon::activated, window,
                     [toggleKeyboard](QSystemTrayIcon::ActivationReason reason) {
        if (reason == QSystemTrayIcon::Trigger
            || reason == QSystemTrayIcon::DoubleClick
            || reason == QSystemTrayIcon::MiddleClick) {
            toggleKeyboard();
        }
    });
    if (QSystemTrayIcon::isSystemTrayAvailable()) {
        trayIcon.show();
    } else {
        qWarning() << "System tray is not available; use the Imboard launcher to toggle";
    }

    if (!inputController.setupRequired()) {
        QTimer::singleShot(0, &inputController,
                           &InputController::restorePortalIfConfigured);
    }

    if (!startHidden) window->show();

    if (smokeTest && !SmokeTestController::schedule(app, window, appearance))
        return 6;

    return app.exec();
}
