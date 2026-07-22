// SPDX-FileCopyrightText: 2026 AnicetusCer
// SPDX-License-Identifier: GPL-3.0-or-later

import QtQuick
import QtQuick.Controls
import QtQuick.Window

Window {
    id: root

    required property var appearanceStore
    required property var compatibilityStore
    required property var customKeyStore
    required property var inputController
    required property var keyboardLayoutStore
    required property var startupManager
    required property var surfaceController
    required property bool suppressInitialSetup

    readonly property string appVersion: "0.4.1"
    readonly property int customPadKeyCount: Math.max(1, Math.min(16, appearanceStore.customPadKeyCount))
    readonly property int customPadColumns: appearanceStore.customPadColumns > 0
                                            ? Math.min(appearanceStore.customPadColumns,
                                                       customPadKeyCount)
                                            : customPadKeyCount <= 1 ? 1
                                              : customPadKeyCount <= 4 ? 2
                                              : customPadKeyCount <= 9 ? 3 : 4
    readonly property int customPadRows: Math.ceil(customPadKeyCount / customPadColumns)
    readonly property int customPadWidth: Math.max(190, customPadColumns * 74 + 38)
    readonly property int customPadHeight: Math.max(120, customPadRows * 58 + 72)
    readonly property int customPadEditorWidth: Math.max(customPadWidth, 360)
    readonly property int customPadEditorHeight: Math.max(customPadHeight, 220)
    readonly property bool customPadEditorMode: keyboardSurface.customPadEditorMode
    property int savedCompactPadWidth: 0
    property int savedCompactPadHeight: 0
    property bool portalBusy: inputController.backendStatus.indexOf("Requesting") === 0
                              || inputController.backendStatus.indexOf("Waiting") === 0

    function showRequiredSetup() {
        if (visible && inputController.setupRequired && !suppressInitialSetup
                && !compatibilityStore.nonKdeWarningRequired
                && !portalExplanationPopup.opened)
            portalExplanationPopup.open()
    }

    function showCompatibilityWarning() {
        if (visible && compatibilityStore.nonKdeWarningRequired
                && !suppressInitialSetup && !compatibilityWarningPopup.opened)
            compatibilityWarningPopup.open()
    }

    function showStartupPrompt() {
        if (visible && inputController.backendReady && startupManager.promptRequired
                && !compatibilityStore.nonKdeWarningRequired
                && !suppressInitialSetup && !startupPromptPopup.opened)
            startupPromptPopup.open()
    }

    width: Math.min(Screen.width, 1120)
    height: Math.min(Screen.height * 0.44, 350)
    minimumWidth: appearanceStore.customPadOnlyEnabled
                  ? customPadEditorMode ? customPadEditorWidth : customPadWidth
                  : 720
    minimumHeight: appearanceStore.customPadOnlyEnabled
                   ? customPadEditorMode ? customPadEditorHeight : customPadHeight
                   : 260
    visible: false
    color: "transparent"
    flags: Qt.Tool
           | Qt.FramelessWindowHint
           | Qt.WindowStaysOnTopHint
           | Qt.WindowDoesNotAcceptFocus
    title: "Imboard"

    Component.onCompleted: showRequiredSetup()
    onVisibleChanged: {
        showCompatibilityWarning()
        showRequiredSetup()
        showStartupPrompt()
    }

    onCustomPadEditorModeChanged: {
        if (!appearanceStore.customPadOnlyEnabled) return

        if (customPadEditorMode) {
            savedCompactPadWidth = width
            savedCompactPadHeight = height
            width = Math.min(Screen.width, Math.max(width, customPadEditorWidth))
            height = Math.min(Screen.height, Math.max(height, customPadEditorHeight))
        } else if (savedCompactPadWidth > 0 && savedCompactPadHeight > 0) {
            width = Math.max(customPadWidth, savedCompactPadWidth)
            height = Math.max(customPadHeight, savedCompactPadHeight)
            savedCompactPadWidth = 0
            savedCompactPadHeight = 0
        }
    }

    Connections {
        target: root.compatibilityStore
        function onNonKdeWarningRequiredChanged() {
            if (!root.compatibilityStore.nonKdeWarningRequired) {
                compatibilityWarningPopup.close()
                root.showRequiredSetup()
                root.showStartupPrompt()
            } else {
                root.showCompatibilityWarning()
            }
        }
    }

    Connections {
        target: root.inputController
        function onBackendReadyChanged() {
            if (root.inputController.backendReady) {
                portalExplanationPopup.close()
                root.showStartupPrompt()
            }
        }
    }

    Connections {
        target: root.startupManager
        function onPromptRequiredChanged() {
            if (!root.startupManager.promptRequired)
                startupPromptPopup.close()
            else
                root.showStartupPrompt()
        }
    }

    Window {
        id: dragPreviewWindow
        objectName: "dragPreviewWindow"
        visible: false
        width: Screen.width
        height: Screen.height
        color: "transparent"
        flags: Qt.Tool
               | Qt.FramelessWindowHint
               | Qt.WindowStaysOnTopHint
               | Qt.WindowDoesNotAcceptFocus
               | Qt.WindowTransparentForInput

        Rectangle {
            x: root.surfaceController.previewPosition.x
            y: root.surfaceController.previewPosition.y
            width: root.surfaceController.previewSize.width
            height: root.surfaceController.previewSize.height
            radius: 18
            visible: root.surfaceController.previewVisible
            color: Qt.alpha(root.appearanceStore.primary, 0.08)
            border.width: 6
            border.color: root.appearanceStore.primary

            Rectangle {
                anchors.fill: parent
                anchors.margins: 8
                radius: 12
                color: "transparent"
                border.width: 3
                border.color: root.appearanceStore.secondary
            }

            Label {
                anchors.centerIn: parent
                text: "MOVE IMBOARD"
                color: root.appearanceStore.primary
                font.bold: true
                font.pixelSize: 18
                style: Text.Outline
                styleColor: "#f0000000"
            }
        }
    }

    KeyboardSurface {
        id: keyboardSurface
        anchors.fill: parent
        appearanceStore: root.appearanceStore
        customKeyStore: root.customKeyStore
        inputController: root.inputController
        keyboardLayoutStore: root.keyboardLayoutStore
        surfaceController: root.surfaceController
        onAboutRequested: aboutPopup.open()
        onAppearanceRequested: appearancePopup.open()
        onConfigurationRequested: configPopup.open()
        onLayoutRequested: layoutPopup.open()
        onExitRequested: Qt.quit()
    }

    AboutPopup {
        id: aboutPopup
        parent: Overlay.overlay
        appearanceStore: root.appearanceStore
        appVersion: root.appVersion
    }

    CompatibilityWarningPopup {
        id: compatibilityWarningPopup
        parent: Overlay.overlay
        appearanceStore: root.appearanceStore
        compatibilityStore: root.compatibilityStore
    }

    AppearancePopup {
        id: appearancePopup
        parent: Overlay.overlay
        appearanceStore: root.appearanceStore
    }

    LayoutPopup {
        id: layoutPopup
        parent: Overlay.overlay
        appearanceStore: root.appearanceStore
        keyboardLayoutStore: root.keyboardLayoutStore
    }

    ConfigPopup {
        id: configPopup
        parent: Overlay.overlay
        appearanceStore: root.appearanceStore
        inputController: root.inputController
        startupManager: root.startupManager
        portalBusy: root.portalBusy
        onPermissionSetupRequested: portalExplanationPopup.open()
        onRemoveAccessRequested: removeAccessPopup.open()
    }

    PermissionSetupPopup {
        id: portalExplanationPopup
        parent: Overlay.overlay
        appearanceStore: root.appearanceStore
        hostWindow: root
        inputController: root.inputController
        portalBusy: root.portalBusy
    }

    RemoveAccessPopup {
        id: removeAccessPopup
        parent: Overlay.overlay
        appearanceStore: root.appearanceStore
        inputController: root.inputController
    }

    StartupPromptPopup {
        id: startupPromptPopup
        parent: Overlay.overlay
        appearanceStore: root.appearanceStore
        startupManager: root.startupManager
    }
}
