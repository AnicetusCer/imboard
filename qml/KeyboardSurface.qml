// SPDX-FileCopyrightText: 2026 AnicetusCer
// SPDX-License-Identifier: GPL-3.0-or-later

import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Rectangle {
    id: root
    objectName: "keyboardSurface"

    required property var appearanceStore
    required property var customKeyStore
    required property var inputController
    required property var keyboardLayoutStore
    required property var speechController
    required property var surfaceController

    readonly property bool customPadEditorMode: customPadOnlyPage.editorMode
    readonly property bool transcriptionActive: transcriptionStrip.active
    readonly property string transcriptDeliveryError: transcriptionStrip.deliveryError

    function beginTranscription() {
        transcriptionStrip.beginTranscription()
    }

    function cancelTranscription() {
        transcriptionStrip.cancelTranscription()
    }

    function applyTranscription() {
        transcriptionStrip.applyTranscription()
    }

    signal appearanceRequested
    signal aboutRequested
    signal configurationRequested
    signal layoutRequested
    signal speechSetupRequested
    signal exitRequested

    radius: 18
    color: Qt.rgba(0.02, 0.035, 0.07, root.appearanceStore.backdropOpacity)
    border.width: root.appearanceStore.frameBordersVisible ? 7 : 0
    border.color: Qt.alpha(root.appearanceStore.primary, 0.26)

    Rectangle {
        anchors.fill: parent
        anchors.margins: 3
        radius: 15
        color: "transparent"
        border.width: root.appearanceStore.frameBordersVisible ? 2 : 0
        border.color: root.appearanceStore.primary
    }

    Rectangle {
        anchors.fill: parent
        anchors.margins: 7
        radius: 13
        color: "transparent"
        border.width: root.appearanceStore.frameBordersVisible ? 2 : 0
        border.color: root.appearanceStore.secondary
    }

    KeyboardHeader {
        id: header
        visible: !root.appearanceStore.customPadOnlyEnabled
                 && !transcriptionStrip.active
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.margins: 10
        appearanceStore: root.appearanceStore
        keyboardLayoutStore: root.keyboardLayoutStore
        speechController: root.speechController
        surfaceController: root.surfaceController
        onAboutRequested: root.aboutRequested()
        onAppearanceRequested: root.appearanceRequested()
        onConfigurationRequested: root.configurationRequested()
        onLayoutRequested: root.layoutRequested()
        onTranscriptionRequested: transcriptionStrip.beginTranscription()
        onSpeechSetupRequested: root.speechSetupRequested()
        onExitRequested: root.exitRequested()
    }

    TranscriptionStrip {
        id: transcriptionStrip
        visible: !root.appearanceStore.customPadOnlyEnabled && active
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.margins: 10
        appearanceStore: root.appearanceStore
        inputController: root.inputController
        speechController: root.speechController
    }

    CompactPadHeader {
        id: compactHeader
        visible: root.appearanceStore.customPadOnlyEnabled
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.margins: 10
        appearanceStore: root.appearanceStore
        customPadPage: customPadOnlyPage
        surfaceController: root.surfaceController
    }

    CustomPadOnlyPage {
        id: customPadOnlyPage
        objectName: "customPadOnlyPage"
        visible: root.appearanceStore.customPadOnlyEnabled
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: compactHeader.bottom
        anchors.bottom: parent.bottom
        anchors.leftMargin: 12
        anchors.rightMargin: 12
        anchors.topMargin: 8
        anchors.bottomMargin: 14
        appearanceStore: root.appearanceStore
        customKeyStore: root.customKeyStore
        inputBackend: root.inputController
    }

    RowLayout {
        visible: !root.appearanceStore.customPadOnlyEnabled
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: transcriptionStrip.active ? transcriptionStrip.bottom : header.bottom
        anchors.bottom: parent.bottom
        anchors.leftMargin: 12
        anchors.rightMargin: 12
        anchors.topMargin: 8
        anchors.bottomMargin: 12
        spacing: 12
        layoutDirection: root.appearanceStore.developerPadOnLeft
                         ? Qt.RightToLeft : Qt.LeftToRight

        Rectangle {
            objectName: "alphaPanel"
            Layout.fillWidth: true
            Layout.fillHeight: true
            Layout.preferredWidth: 780
            radius: 14
            color: "transparent"
            border.width: root.appearanceStore.frameBordersVisible ? 2 : 0
            border.color: root.appearanceStore.primary

            Rectangle {
                anchors.fill: parent
                anchors.margins: 5
                radius: 10
                color: "transparent"
                border.width: root.appearanceStore.frameBordersVisible ? 1 : 0
                border.color: Qt.alpha(root.appearanceStore.secondary, 0.66)
            }

            AlphaBoard {
                id: alphaBoard
                anchors.fill: parent
                anchors.margins: 8
                appearanceStore: root.appearanceStore
                inputBackend: root.inputController
                layoutStore: root.keyboardLayoutStore
            }
        }

        Rectangle {
            objectName: "developerPanel"
            Layout.fillWidth: true
            Layout.fillHeight: true
            Layout.preferredWidth: 310
            radius: 14
            color: "transparent"
            border.width: root.appearanceStore.frameBordersVisible ? 2 : 0
            border.color: root.appearanceStore.secondary

            Rectangle {
                anchors.fill: parent
                anchors.margins: 5
                radius: 10
                color: "transparent"
                border.width: root.appearanceStore.frameBordersVisible ? 1 : 0
                border.color: Qt.alpha(root.appearanceStore.primary, 0.66)
            }

            DeveloperPad {
                anchors.fill: parent
                anchors.margins: 8
                appearanceStore: root.appearanceStore
                customKeyStore: root.customKeyStore
                inputBackend: root.inputController
                modifierSource: alphaBoard
            }
        }
    }

    Rectangle {
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        anchors.margins: 5
        width: 30
        height: 30
        color: "transparent"

        Label {
            anchors.centerIn: parent
            text: "◢"
            color: root.appearanceStore.secondary
            font.pixelSize: 19
            style: Text.Outline
            styleColor: "#f0000000"
        }

        MouseArea {
            anchors.fill: parent
            cursorShape: Qt.SizeFDiagCursor
            property bool resizing: false
            onPressed: function(mouse) {
                resizing = true
                root.surfaceController.beginResize(mapToGlobal(mouse.x, mouse.y))
            }
            onPositionChanged: function(mouse) {
                if (resizing)
                    root.surfaceController.updateResize(mapToGlobal(mouse.x, mouse.y))
            }
            onReleased: {
                resizing = false
                root.surfaceController.finishInteraction()
            }
            onCanceled: {
                resizing = false
                root.surfaceController.finishInteraction()
            }
        }
    }
}
