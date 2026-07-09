// SPDX-FileCopyrightText: 2026 AnicetusCer
// SPDX-License-Identifier: GPL-3.0-or-later

#include "smoketestcontroller.h"

#include "appearancestore.h"

#include <QDebug>
#include <QGuiApplication>
#include <QMetaObject>
#include <QObject>
#include <QTimer>
#include <QVariant>
#include <QWindow>

namespace
{
bool invoke(QObject *object, const char *method)
{
    if (QMetaObject::invokeMethod(object, method)) return true;
    qCritical() << "Smoke test could not invoke" << method << "on" << object;
    return false;
}
}

namespace SmokeTestController
{
bool schedule(QGuiApplication &app, QWindow *window, AppearanceStore &appearance)
{
    auto *picker = window->findChild<QObject *>(QStringLiteral("customKeyPicker"));
    auto *grid = window->findChild<QObject *>(QStringLiteral("availableKeyGrid"));
    auto *aboutPopup = window->findChild<QObject *>(QStringLiteral("aboutPopup"));
    auto *appearancePopup = window->findChild<QObject *>(QStringLiteral("appearancePopup"));
    auto *layoutPopup = window->findChild<QObject *>(QStringLiteral("layoutPopup"));
    auto *configPopup = window->findChild<QObject *>(QStringLiteral("configPopup"));
    auto *portalExplanationPopup =
        window->findChild<QObject *>(QStringLiteral("portalExplanationPopup"));
    auto *removeAccessPopup =
        window->findChild<QObject *>(QStringLiteral("removeAccessPopup"));
    auto *alphaPanel = window->findChild<QObject *>(QStringLiteral("alphaPanel"));
    auto *developerPanel = window->findChild<QObject *>(QStringLiteral("developerPanel"));
    auto *customPadOnlyPage = window->findChild<QObject *>(QStringLiteral("customPadOnlyPage"));
    auto *customPadOnlyGrid = window->findChild<QObject *>(QStringLiteral("customPadOnlyGrid"));

    if (!picker || !grid || !aboutPopup || !appearancePopup || !layoutPopup || !configPopup
        || !portalExplanationPopup || !removeAccessPopup
        || !alphaPanel || !developerPanel || !customPadOnlyPage || !customPadOnlyGrid
        || !invoke(picker, "open")) {
        qCritical() << "Could not open the custom-key picker during smoke test";
        return false;
    }

    QTimer::singleShot(150, &app, [grid]() {
        const qreal contentHeight = grid->property("contentHeight").toReal();
        const qreal height = grid->property("height").toReal();
        const qreal maximumY = qMax(0.0, contentHeight - height);
        grid->setProperty("contentY", maximumY * 0.8);
    });
    QTimer::singleShot(350, &app, [grid]() {
        const qreal contentHeight = grid->property("contentHeight").toReal();
        const qreal height = grid->property("height").toReal();
        grid->setProperty("contentY", qMax(0.0, contentHeight - height));
    });
    QTimer::singleShot(650, &app, [&app, picker, grid, aboutPopup]() {
        const qreal width = grid->property("width").toReal();
        const qreal height = grid->property("height").toReal();
        if (width < 100.0 || height < 100.0) {
            qCritical() << "Custom-key grid collapsed during smoke test:" << width << height;
            app.exit(6);
            return;
        }
        if (!invoke(picker, "close") || !invoke(aboutPopup, "open"))
            app.exit(6);
    });
    QTimer::singleShot(900, &app, [&app, aboutPopup, appearancePopup]() {
        const qreal width = aboutPopup->property("width").toReal();
        const qreal height = aboutPopup->property("height").toReal();
        if (width < 300.0 || height < 180.0) {
            qCritical() << "About popup collapsed during smoke test:"
                        << width << height;
            app.exit(7);
            return;
        }
        if (!invoke(aboutPopup, "close") || !invoke(appearancePopup, "open"))
            app.exit(7);
    });
    QTimer::singleShot(1150, &app, [&app, appearancePopup, layoutPopup]() {
        const qreal width = appearancePopup->property("width").toReal();
        const qreal height = appearancePopup->property("height").toReal();
        const qreal presetHeight = appearancePopup->property("renderedOptionHeight").toReal();
        if (width < 300.0 || height < 150.0 || presetHeight < 40.0) {
            qCritical() << "Appearance popup collapsed during smoke test:"
                        << width << height << presetHeight;
            app.exit(8);
            return;
        }
        if (!invoke(appearancePopup, "close") || !invoke(layoutPopup, "open"))
            app.exit(8);
    });
    QTimer::singleShot(1400, &app, [&app, &appearance, layoutPopup]() {
        const qreal width = layoutPopup->property("width").toReal();
        const qreal height = layoutPopup->property("height").toReal();
        const qreal choiceHeight = layoutPopup->property("renderedOptionHeight").toReal();
        if (width < 300.0 || height < 150.0 || choiceHeight < 40.0) {
            qCritical() << "Layout popup collapsed during smoke test:"
                        << width << height << choiceHeight;
            app.exit(9);
            return;
        }
        if (!invoke(layoutPopup, "close")) {
            app.exit(9);
            return;
        }
        appearance.toggleDeveloperPadSide();
    });
    QTimer::singleShot(1600, &app,
                       [&app, &appearance, configPopup, alphaPanel, developerPanel]() {
        const qreal alphaX = alphaPanel->property("x").toReal();
        const qreal developerX = developerPanel->property("x").toReal();
        const bool orderMatches = appearance.developerPadOnLeft()
                                  ? developerX < alphaX : alphaX < developerX;
        appearance.toggleDeveloperPadSide();
        if (!orderMatches) {
            qCritical() << "Developer-pad side toggle did not reverse panel order:"
                        << alphaX << developerX;
            app.exit(10);
            return;
        }
        if (!invoke(configPopup, "open")) app.exit(10);
    });
    QTimer::singleShot(1850, &app, [&app, configPopup, portalExplanationPopup]() {
        const qreal width = configPopup->property("width").toReal();
        const qreal height = configPopup->property("height").toReal();
        if (width < 300.0 || height < 150.0) {
            qCritical() << "Configuration popup collapsed during smoke test:"
                        << width << height;
            app.exit(11);
            return;
        }
        if (!invoke(configPopup, "close") || !invoke(portalExplanationPopup, "open"))
            app.exit(11);
    });
    QTimer::singleShot(2100, &app, [&app, portalExplanationPopup, removeAccessPopup]() {
        const qreal width = portalExplanationPopup->property("width").toReal();
        const qreal height = portalExplanationPopup->property("height").toReal();
        if (width < 400.0 || height < 180.0) {
            qCritical() << "Portal explanation popup collapsed during smoke test:"
                        << width << height;
            app.exit(12);
            return;
        }
        if (!invoke(portalExplanationPopup, "close")
            || !invoke(removeAccessPopup, "open")) {
            app.exit(12);
        }
    });
    QTimer::singleShot(2350, &app, [&app, &appearance, removeAccessPopup]() {
        const qreal width = removeAccessPopup->property("width").toReal();
        const qreal height = removeAccessPopup->property("height").toReal();
        if (width < 400.0 || height < 180.0) {
            qCritical() << "Remove-access popup collapsed during smoke test:"
                        << width << height;
            app.exit(13);
            return;
        }
        if (!invoke(removeAccessPopup, "close")) {
            app.exit(13);
            return;
        }
        appearance.setCustomPadKeyCount(4);
        appearance.setCustomPadColumns(2);
        appearance.setCustomPadOnlyEnabled(true);
    });
    QTimer::singleShot(2600, &app, [&app, customPadOnlyPage, customPadOnlyGrid]() {
        const qreal width = customPadOnlyGrid->property("width").toReal();
        const qreal height = customPadOnlyGrid->property("height").toReal();
        if (width < 100.0 || height < 80.0) {
            qCritical() << "Custom-pad-only grid collapsed during smoke test:"
                        << width << height;
            app.exit(14);
            return;
        }
        if (!invoke(customPadOnlyPage, "beginEdit"))
            app.exit(14);
    });
    QTimer::singleShot(2850, &app, [&app, &appearance, customPadOnlyPage]() {
        if (!customPadOnlyPage->property("editMode").toBool()) {
            qCritical() << "Custom-pad edit mode did not open";
            app.exit(15);
            return;
        }
        if (!invoke(customPadOnlyPage, "finishEdit")) {
            app.exit(15);
            return;
        }
        appearance.setCustomPadOnlyEnabled(false);
        app.quit();
    });

    return true;
}
}
