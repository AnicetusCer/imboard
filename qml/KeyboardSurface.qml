// SPDX-FileCopyrightText: 2026 AnicetusCer
// SPDX-License-Identifier: GPL-3.0-or-later

import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Rectangle {
    id: root

    required property var appearanceStore
    required property var customKeyStore
    required property var inputController
    required property var keyboardLayoutStore
    required property var surfaceController

    signal appearanceRequested
    signal aboutRequested
    signal configurationRequested
    signal layoutRequested
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

    Rectangle {
        id: header
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.margins: 10
        height: 42
        radius: 8
        color: "transparent"
        border.width: root.appearanceStore.frameBordersVisible ? 2 : 0
        border.color: root.appearanceStore.primary

        MouseArea {
            anchors.left: exitButton.right
            anchors.right: padSideButton.left
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
            anchors.right: padSideButton.left
            anchors.rightMargin: 8
            anchors.verticalCenter: parent.verticalCenter
            text: "⠿  IMBOARD"
            color: Qt.lighter(root.appearanceStore.primary, 1.25)
            font.pixelSize: 12
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
                onClicked: {
                    root.exitRequested()
                    Qt.quit()
                }
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
    }

    RowLayout {
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: header.bottom
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
