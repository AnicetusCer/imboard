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
enum SmokeExitCode {
    CustomKeyPickerFailure = 6,
    AboutPopupFailure,
    AppearancePopupFailure,
    LayoutPopupFailure,
    DeveloperPadFailure,
    ConfigPopupFailure,
    PermissionPopupFailure,
    RemoveAccessPopupFailure,
    CompactPadFailure,
    CompactPadEditorFailure,
    TranscriptionStripFailure,
    SpeechSetupPopupFailure,
};

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
    auto *speechSetupPopup =
        window->findChild<QObject *>(QStringLiteral("speechSetupPopup"));
    auto *layoutPopupContent =
        window->findChild<QObject *>(QStringLiteral("layoutPopupContent"));
    auto *layoutOptionsGrid =
        window->findChild<QObject *>(QStringLiteral("layoutOptionsGrid"));
    auto *configPopup = window->findChild<QObject *>(QStringLiteral("configPopup"));
    auto *portalExplanationPopup =
        window->findChild<QObject *>(QStringLiteral("portalExplanationPopup"));
    auto *removeAccessPopup =
        window->findChild<QObject *>(QStringLiteral("removeAccessPopup"));
    auto *alphaPanel = window->findChild<QObject *>(QStringLiteral("alphaPanel"));
    auto *developerPanel = window->findChild<QObject *>(QStringLiteral("developerPanel"));
    auto *customPadOnlyPage = window->findChild<QObject *>(QStringLiteral("customPadOnlyPage"));
    auto *customPadOnlyGrid = window->findChild<QObject *>(QStringLiteral("customPadOnlyGrid"));
    auto *keyboardSurface =
        window->findChild<QObject *>(QStringLiteral("keyboardSurface"));
    auto *transcriptionStrip =
        window->findChild<QObject *>(QStringLiteral("transcriptionStrip"));
    auto *transcriptionButton =
        window->findChild<QObject *>(QStringLiteral("transcriptionButton"));
    auto *padSideButton =
        window->findChild<QObject *>(QStringLiteral("padSideButton"));
    auto *transcriptViewport =
        window->findChild<QObject *>(QStringLiteral("transcriptViewport"));
    auto *transcriptArea = window->findChild<QObject *>(QStringLiteral("transcriptArea"));

    if (!picker || !grid || !aboutPopup || !appearancePopup || !layoutPopup
        || !speechSetupPopup
        || !layoutPopupContent || !layoutOptionsGrid || !configPopup
        || !portalExplanationPopup || !removeAccessPopup
        || !alphaPanel || !developerPanel || !customPadOnlyPage || !customPadOnlyGrid
        || !keyboardSurface || !transcriptionStrip || !transcriptionButton
        || !padSideButton || !transcriptViewport
        || !transcriptArea
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
            app.exit(CustomKeyPickerFailure);
            return;
        }
        if (!invoke(picker, "close") || !invoke(aboutPopup, "open"))
            app.exit(CustomKeyPickerFailure);
    });
    QTimer::singleShot(900, &app, [&app, aboutPopup, appearancePopup]() {
        const qreal width = aboutPopup->property("width").toReal();
        const qreal height = aboutPopup->property("height").toReal();
        if (width < 300.0 || height < 180.0) {
            qCritical() << "About popup collapsed during smoke test:"
                        << width << height;
            app.exit(AboutPopupFailure);
            return;
        }
        if (!invoke(aboutPopup, "close") || !invoke(appearancePopup, "open"))
            app.exit(AboutPopupFailure);
    });
    QTimer::singleShot(1150, &app, [&app, window, appearancePopup, layoutPopup]() {
        const qreal width = appearancePopup->property("width").toReal();
        const qreal height = appearancePopup->property("height").toReal();
        const qreal presetHeight = appearancePopup->property("renderedOptionHeight").toReal();
        if (width < 300.0 || height < 150.0 || presetHeight < 40.0) {
            qCritical() << "Appearance popup collapsed during smoke test:"
                        << width << height << presetHeight;
            app.exit(AppearancePopupFailure);
            return;
        }
        window->resize(window->minimumWidth(), window->minimumHeight());
        if (!invoke(appearancePopup, "close") || !invoke(layoutPopup, "open"))
            app.exit(AppearancePopupFailure);
    });
    QTimer::singleShot(1400, &app,
                       [&app, &appearance, layoutPopup, layoutPopupContent,
                        layoutOptionsGrid, transcriptionButton, padSideButton]() {
        const qreal width = layoutPopup->property("width").toReal();
        const qreal height = layoutPopup->property("height").toReal();
        const qreal choiceHeight = layoutPopup->property("renderedOptionHeight").toReal();
        const qreal gridBottom = layoutOptionsGrid->property("y").toReal()
                                 + layoutOptionsGrid->property("height").toReal();
        const qreal contentHeight = layoutPopupContent->property("height").toReal();
        const qreal transcriptionRight = transcriptionButton->property("x").toReal()
                                           + transcriptionButton->property("width").toReal();
        const qreal padLeft = padSideButton->property("x").toReal();
        if (width < 300.0 || height < 150.0 || choiceHeight < 40.0
            || gridBottom > contentHeight + 0.5 || transcriptionRight > padLeft) {
            qCritical() << "Layout popup collapsed during smoke test:"
                        << width << height << choiceHeight
                        << gridBottom << contentHeight
                        << transcriptionRight << padLeft;
            app.exit(LayoutPopupFailure);
            return;
        }
        if (!invoke(layoutPopup, "close")) {
            app.exit(LayoutPopupFailure);
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
            app.exit(DeveloperPadFailure);
            return;
        }
        if (!invoke(configPopup, "open")) app.exit(DeveloperPadFailure);
    });
    QTimer::singleShot(1850, &app, [&app, configPopup, portalExplanationPopup]() {
        const qreal width = configPopup->property("width").toReal();
        const qreal height = configPopup->property("height").toReal();
        if (width < 300.0 || height < 150.0) {
            qCritical() << "Configuration popup collapsed during smoke test:"
                        << width << height;
            app.exit(ConfigPopupFailure);
            return;
        }
        if (!invoke(configPopup, "close") || !invoke(portalExplanationPopup, "open"))
            app.exit(ConfigPopupFailure);
    });
    QTimer::singleShot(2100, &app, [&app, portalExplanationPopup, removeAccessPopup]() {
        const qreal width = portalExplanationPopup->property("width").toReal();
        const qreal height = portalExplanationPopup->property("height").toReal();
        if (width < 400.0 || height < 180.0) {
            qCritical() << "Portal explanation popup collapsed during smoke test:"
                        << width << height;
            app.exit(PermissionPopupFailure);
            return;
        }
        if (!invoke(portalExplanationPopup, "close")
            || !invoke(removeAccessPopup, "open")) {
            app.exit(PermissionPopupFailure);
        }
    });
    QTimer::singleShot(2350, &app, [&app, &appearance, removeAccessPopup]() {
        const qreal width = removeAccessPopup->property("width").toReal();
        const qreal height = removeAccessPopup->property("height").toReal();
        if (width < 400.0 || height < 180.0) {
            qCritical() << "Remove-access popup collapsed during smoke test:"
                        << width << height;
            app.exit(RemoveAccessPopupFailure);
            return;
        }
        if (!invoke(removeAccessPopup, "close")) {
            app.exit(RemoveAccessPopupFailure);
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
            app.exit(CompactPadFailure);
            return;
        }
        if (!invoke(customPadOnlyPage, "beginEdit"))
            app.exit(CompactPadFailure);
    });
    QTimer::singleShot(2850, &app,
                       [&app, &appearance, customPadOnlyPage]() {
        if (!customPadOnlyPage->property("editMode").toBool()) {
            qCritical() << "Custom-pad edit mode did not open";
            app.exit(CompactPadEditorFailure);
            return;
        }
        if (!invoke(customPadOnlyPage, "finishEdit")) {
            app.exit(CompactPadEditorFailure);
            return;
        }
        appearance.setCustomPadOnlyEnabled(false);
    });
    QTimer::singleShot(2950, &app, [&app, window, keyboardSurface]() {
        if (window->width() < window->minimumWidth()) {
            qCritical() << "Full keyboard size was not restored before transcription:"
                        << window->width() << window->minimumWidth();
            app.exit(TranscriptionStripFailure);
            return;
        }
        if (!invoke(keyboardSurface, "beginTranscription"))
            app.exit(TranscriptionStripFailure);
    });
    QTimer::singleShot(3100, &app, [&app, keyboardSurface, transcriptArea]() {
        const QString longTranscript =
            QStringLiteral("A deliberately long local transcript used to verify that wrapped text "
                           "stays clear of the scrollbar and that the final lines can scroll fully "
                           "into view. ").repeated(8);
        transcriptArea->setProperty("text", longTranscript);
        transcriptArea->setProperty("cursorPosition", longTranscript.size());
        if (!invoke(keyboardSurface, "applyTranscription"))
            app.exit(TranscriptionStripFailure);
    });
    QTimer::singleShot(3300, &app,
                       [&app, keyboardSurface, transcriptionStrip,
                        transcriptViewport, transcriptArea, speechSetupPopup]() {
        const qreal width = transcriptionStrip->property("width").toReal();
        const qreal height = transcriptionStrip->property("height").toReal();
        const qreal viewportWidth = transcriptViewport->property("width").toReal();
        const qreal viewportHeight = transcriptViewport->property("height").toReal();
        const qreal contentHeight = transcriptViewport->property("contentHeight").toReal();
        const qreal editorWidth = transcriptArea->property("width").toReal();
        const qreal editorHeight = transcriptArea->property("height").toReal();
        const QString deliveryError =
            keyboardSurface->property("transcriptDeliveryError").toString();
        if (!transcriptionStrip->property("visible").toBool()
            || width < 600.0 || height < 70.0
            || editorWidth < 400.0 || editorHeight < 24.0
            || editorWidth > viewportWidth - 12.0
            || contentHeight <= viewportHeight
            || transcriptArea->property("text").toString().isEmpty()
            || deliveryError.isEmpty()) {
            qCritical() << "Transcription strip collapsed during smoke test:"
                        << width << height << viewportWidth << viewportHeight
                        << contentHeight << editorWidth << editorHeight
                        << deliveryError;
            app.exit(TranscriptionStripFailure);
            return;
        }
        if (!invoke(keyboardSurface, "cancelTranscription")
            || !invoke(speechSetupPopup, "open")) {
            app.exit(TranscriptionStripFailure);
            return;
        }
    });
    QTimer::singleShot(3500, &app, [&app, speechSetupPopup]() {
        const qreal width = speechSetupPopup->property("width").toReal();
        const qreal height = speechSetupPopup->property("height").toReal();
        if (width < 400.0 || height < 180.0) {
            qCritical() << "Speech setup popup collapsed during smoke test:"
                        << width << height;
            app.exit(SpeechSetupPopupFailure);
            return;
        }
        if (!invoke(speechSetupPopup, "close")) {
            app.exit(SpeechSetupPopupFailure);
            return;
        }
        app.quit();
    });

    return true;
}
}
