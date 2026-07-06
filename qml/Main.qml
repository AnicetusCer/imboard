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
    minimumWidth: 720
    minimumHeight: 260
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
