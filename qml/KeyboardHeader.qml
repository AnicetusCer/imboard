// SPDX-FileCopyrightText: 2026 AnicetusCer
// SPDX-License-Identifier: GPL-3.0-or-later

import QtQuick
import QtQuick.Controls

Rectangle {
    id: root

    required property var appearanceStore
    required property var keyboardLayoutStore
    required property var inputController
    required property var speechController
    required property var surfaceController

    signal aboutRequested
    signal appearanceRequested
    signal configurationRequested
    signal layoutRequested
    signal transcriptionRequested
    signal speechSetupRequested
    signal exitRequested

    objectName: "keyboardHeader"
    height: 42
    radius: 8
    color: "transparent"
    border.width: root.appearanceStore.frameBordersVisible ? 2 : 0
    border.color: root.appearanceStore.primary

    MouseArea {
        anchors.left: exitButton.right
        anchors.right: root.inputController.inputDiagnosticsEnabled
                       ? transcriptionButton.left : padSideButton.left
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        anchors.leftMargin: 6
        anchors.rightMargin: 8
        cursorShape: Qt.SizeAllCursor
        property bool moving: false
        onPressed: function(mouse) {
            moving = true
            root.surfaceController.beginMove(mapToGlobal(mouse.x, mouse.y))
        }
        onPositionChanged: function(mouse) {
            if (moving)
                root.surfaceController.updateMove(mapToGlobal(mouse.x, mouse.y))
        }
        onReleased: {
            moving = false
            root.surfaceController.finishInteraction()
        }
        onCanceled: {
            moving = false
            root.surfaceController.finishInteraction()
        }
    }

    Label {
        id: titleLabel
        anchors.left: exitButton.right
        anchors.leftMargin: 10
        anchors.right: root.inputController.inputDiagnosticsEnabled
                       ? transcriptionButton.left : padSideButton.left
        anchors.rightMargin: 8
        anchors.verticalCenter: parent.verticalCenter
        text: root.inputController.inputDiagnosticsEnabled
              ? root.inputController.diagnosticSummary : "⠿  IMBOARD"
        color: root.inputController.inputDiagnosticsEnabled
               && root.inputController.diagnosticPortalEventsFailed > 0
               ? "#ff6d91" : Qt.lighter(root.appearanceStore.primary, 1.25)
        font.pixelSize: root.inputController.inputDiagnosticsEnabled ? 9 : 12
        font.bold: true
        style: Text.Outline
        styleColor: "#f0000000"
        elide: Text.ElideRight

        MouseArea {
            width: Math.min(titleLabel.implicitWidth + 12, titleLabel.width)
            height: parent.height
            anchors.left: parent.left
            anchors.verticalCenter: parent.verticalCenter
            onClicked: root.aboutRequested()
        }
    }

    Rectangle {
        id: exitButton
        anchors.left: parent.left
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        width: 42
        radius: 7
        color: exitMouse.pressed ? "#55ff6d91" : "transparent"
        border.width: root.appearanceStore.keyBordersVisible ? 2 : 0
        border.color: "#ff6d91"

        Label {
            anchors.centerIn: parent
            text: "✕"
            color: "#ff6d91"
            font.bold: true
            font.pixelSize: 15
            style: Text.Outline
            styleColor: "#f0000000"
        }

        MouseArea {
            id: exitMouse
            anchors.fill: parent
            onClicked: root.exitRequested()
        }
    }

    Rectangle {
        id: styleButton
        anchors.right: configButton.left
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        anchors.rightMargin: 5
        width: 78
        radius: 7
        color: styleMouse.pressed
               ? Qt.alpha(root.appearanceStore.secondary, 0.24) : "transparent"
        border.width: root.appearanceStore.keyBordersVisible ? 2 : 0
        border.color: root.appearanceStore.secondary

        Label {
            anchors.centerIn: parent
            text: "STYLE"
            color: root.appearanceStore.secondary
            font.bold: true
            font.pixelSize: 10
            style: Text.Outline
            styleColor: "#f0000000"
        }

        MouseArea {
            id: styleMouse
            anchors.fill: parent
            onClicked: root.appearanceRequested()
        }
    }

    Rectangle {
        id: configButton
        anchors.right: minimizeButton.left
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        anchors.rightMargin: 5
        width: 78
        radius: 7
        color: configMouse.pressed
               ? Qt.alpha(root.appearanceStore.secondary, 0.24) : "transparent"
        border.width: root.appearanceStore.keyBordersVisible ? 2 : 0
        border.color: root.appearanceStore.secondary

        Label {
            anchors.centerIn: parent
            text: "CONFIG"
            color: root.appearanceStore.secondary
            font.bold: true
            font.pixelSize: 9
            style: Text.Outline
            styleColor: "#f0000000"
        }

        MouseArea {
            id: configMouse
            anchors.fill: parent
            onClicked: root.configurationRequested()
        }
    }

    Rectangle {
        id: minimizeButton
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        width: 62
        radius: 7
        color: minimizeMouse.pressed
               ? Qt.alpha(root.appearanceStore.primary, 0.24) : "transparent"
        border.width: root.appearanceStore.keyBordersVisible ? 2 : 0
        border.color: root.appearanceStore.primary

        Label {
            anchors.centerIn: parent
            text: "MIN"
            color: root.appearanceStore.primary
            font.bold: true
            font.pixelSize: 9
            style: Text.Outline
            styleColor: "#f0000000"
        }

        MouseArea {
            id: minimizeMouse
            anchors.fill: parent
            onClicked: root.surfaceController.hideWindow()
        }
    }

    Rectangle {
        id: layoutButton
        anchors.right: styleButton.left
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        anchors.rightMargin: 5
        width: 90
        radius: 7
        color: layoutMouse.pressed
               ? Qt.alpha(root.appearanceStore.primary, 0.24) : "transparent"
        border.width: root.appearanceStore.keyBordersVisible ? 2 : 0
        border.color: root.appearanceStore.primary

        Label {
            anchors.centerIn: parent
            text: "LAYOUT " + root.keyboardLayoutStore.layoutId.toUpperCase()
            color: root.appearanceStore.primary
            font.bold: true
            font.pixelSize: 9
            style: Text.Outline
            styleColor: "#f0000000"
        }

        MouseArea {
            id: layoutMouse
            anchors.fill: parent
            onClicked: root.layoutRequested()
        }
    }

    Rectangle {
        id: padSideButton
        objectName: "padSideButton"
        anchors.right: layoutButton.left
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        anchors.rightMargin: 5
        width: 62
        radius: 7
        color: padSideMouse.pressed
               ? Qt.alpha(root.appearanceStore.secondary, 0.24) : "transparent"
        border.width: root.appearanceStore.keyBordersVisible ? 2 : 0
        border.color: root.appearanceStore.secondary

        Label {
            anchors.centerIn: parent
            text: root.appearanceStore.developerPadOnLeft ? "PAD ←" : "PAD →"
            color: root.appearanceStore.secondary
            font.bold: true
            font.pixelSize: 9
            style: Text.Outline
            styleColor: "#f0000000"
        }

        MouseArea {
            id: padSideMouse
            anchors.fill: parent
            onClicked: root.appearanceStore.toggleDeveloperPadSide()
        }
    }

    Rectangle {
        id: transcriptionButton
        objectName: "transcriptionButton"
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        x: Math.max(exitButton.x + exitButton.width + 5,
                    Math.min(Math.round((parent.width - width) / 2),
                             padSideButton.x - width - 5))
        width: 116
        radius: 7
        color: transcriptionMouse.pressed
               ? Qt.alpha(root.appearanceStore.primary, 0.24) : "transparent"
        border.width: root.appearanceStore.keyBordersVisible ? 2 : 0
        border.color: root.appearanceStore.primary

        Label {
            anchors.centerIn: parent
            text: root.speechController.available ? "TRANSCRIBE" : "ADD SPEECH"
            color: root.speechController.available
                   ? root.appearanceStore.primary : "#ffb43b"
            font.bold: true
            font.pixelSize: 9
            style: Text.Outline
            styleColor: "#f0000000"
        }

        MouseArea {
            id: transcriptionMouse
            anchors.fill: parent
            onClicked: {
                if (root.speechController.available)
                    root.transcriptionRequested()
                else
                    root.speechSetupRequested()
            }
        }
    }
}
