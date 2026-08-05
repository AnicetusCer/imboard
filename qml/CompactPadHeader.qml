// SPDX-FileCopyrightText: 2026 AnicetusCer
// SPDX-License-Identifier: GPL-3.0-or-later

import QtQuick
import QtQuick.Controls

Rectangle {
    id: root

    required property var appearanceStore
    required property var customPadPage
    required property var surfaceController

    readonly property bool tinyControls: width < 280
    readonly property int controlGap: tinyControls ? 3 : 5
    readonly property bool moveControlsVisible: customPadPage.editMode
                                                && customPadPage.keyCount > 1

    objectName: "compactPadHeader"
    height: 34
    radius: 8
    color: "transparent"
    border.width: root.appearanceStore.frameBordersVisible ? 2 : 0
    border.color: root.appearanceStore.primary

    MouseArea {
        anchors.left: fullModeButton.right
        anchors.right: root.moveControlsVisible ? moveLeftButton.left
                                                : customButton.left
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        anchors.leftMargin: 6
        anchors.rightMargin: 6
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

    Rectangle {
        id: fullModeButton
        anchors.left: parent.left
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        width: root.tinyControls ? 28 : 60
        radius: 7
        color: fullModeMouse.pressed
               ? Qt.alpha(root.appearanceStore.secondary, 0.24) : "transparent"
        border.width: root.appearanceStore.keyBordersVisible ? 2 : 0
        border.color: root.appearanceStore.secondary

        Label {
            anchors.centerIn: parent
            text: root.tinyControls ? "F" : "FULL"
            color: root.appearanceStore.secondary
            font.bold: true
            font.pixelSize: 9
            style: Text.Outline
            styleColor: "#f0000000"
        }

        MouseArea {
            id: fullModeMouse
            anchors.fill: parent
            onClicked: {
                if (root.customPadPage.editMode && !root.customPadPage.finishEdit())
                    return
                root.appearanceStore.setCustomPadOnlyEnabled(false)
            }
        }
    }

    Label {
        anchors.left: fullModeButton.right
        anchors.leftMargin: 10
        anchors.right: root.moveControlsVisible ? moveLeftButton.left
                                                : customButton.left
        anchors.rightMargin: 10
        anchors.verticalCenter: parent.verticalCenter
        text: root.customPadPage.editMode
              ? root.tinyControls ? "EDIT" : "CUSTOMISE"
              : root.tinyControls ? "PAD" : "CUSTOM PAD"
        color: Qt.lighter(root.appearanceStore.primary, 1.25)
        font.pixelSize: 11
        font.bold: true
        style: Text.Outline
        styleColor: "#f0000000"
        elide: Text.ElideRight
    }

    Rectangle {
        id: moveLeftButton
        visible: root.moveControlsVisible
        anchors.right: moveRightButton.left
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        anchors.rightMargin: root.controlGap
        width: 38
        radius: 7
        color: moveLeftMouse.pressed
               ? Qt.alpha(root.appearanceStore.secondary, 0.24) : "transparent"
        border.width: root.appearanceStore.keyBordersVisible ? 2 : 0
        border.color: root.customPadPage.selectedSlot > 0
                      ? root.appearanceStore.secondary : "#666666"

        Label {
            anchors.centerIn: parent
            text: "←"
            color: root.customPadPage.selectedSlot > 0
                   ? root.appearanceStore.secondary : "#777777"
            font.bold: true
            font.pixelSize: 12
            style: Text.Outline
            styleColor: "#f0000000"
        }

        MouseArea {
            id: moveLeftMouse
            anchors.fill: parent
            enabled: root.customPadPage.selectedSlot > 0
            onClicked: root.customPadPage.moveSelectedSlot(-1)
        }
    }

    Rectangle {
        id: moveRightButton
        visible: root.moveControlsVisible
        anchors.right: customButton.left
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        anchors.rightMargin: root.controlGap
        width: 38
        radius: 7
        color: moveRightMouse.pressed
               ? Qt.alpha(root.appearanceStore.secondary, 0.24) : "transparent"
        border.width: root.appearanceStore.keyBordersVisible ? 2 : 0
        border.color: root.customPadPage.selectedSlot >= 0
                      && root.customPadPage.selectedSlot < root.customPadPage.keyCount - 1
                      ? root.appearanceStore.secondary : "#666666"

        Label {
            anchors.centerIn: parent
            text: "→"
            color: root.customPadPage.selectedSlot >= 0
                   && root.customPadPage.selectedSlot < root.customPadPage.keyCount - 1
                   ? root.appearanceStore.secondary : "#777777"
            font.bold: true
            font.pixelSize: 12
            style: Text.Outline
            styleColor: "#f0000000"
        }

        MouseArea {
            id: moveRightMouse
            anchors.fill: parent
            enabled: root.customPadPage.selectedSlot >= 0
                     && root.customPadPage.selectedSlot < root.customPadPage.keyCount - 1
            onClicked: root.customPadPage.moveSelectedSlot(1)
        }
    }

    Rectangle {
        id: customButton
        anchors.right: cancelButton.visible ? cancelButton.left : minimizeButton.left
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        anchors.rightMargin: root.controlGap
        width: root.tinyControls
               ? root.customPadPage.editMode ? 42 : 48
               : root.customPadPage.editMode ? 62 : 96
        radius: 7
        color: customMouse.pressed
               ? Qt.alpha(root.customPadPage.editMode ? "#72ff9f"
                                                      : root.appearanceStore.secondary,
                          0.24)
               : "transparent"
        border.width: root.appearanceStore.keyBordersVisible ? 2 : 0
        border.color: root.customPadPage.editMode ? "#72ff9f"
                                                  : root.appearanceStore.secondary

        Label {
            anchors.centerIn: parent
            text: root.customPadPage.editMode ? "SAVE"
                                             : root.tinyControls ? "EDIT" : "CUSTOMISE"
            color: root.customPadPage.editMode ? "#72ff9f"
                                              : root.appearanceStore.secondary
            font.bold: true
            font.pixelSize: 9
            style: Text.Outline
            styleColor: "#f0000000"
        }

        MouseArea {
            id: customMouse
            anchors.fill: parent
            onClicked: {
                if (root.customPadPage.editMode)
                    root.customPadPage.finishEdit()
                else
                    root.customPadPage.beginEdit()
            }
        }
    }

    Rectangle {
        id: cancelButton
        visible: root.customPadPage.editMode
        anchors.right: minimizeButton.left
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        anchors.rightMargin: root.controlGap
        width: root.tinyControls ? 28 : 68
        radius: 7
        color: cancelMouse.pressed ? Qt.alpha("#ff6d91", 0.24) : "transparent"
        border.width: root.appearanceStore.keyBordersVisible ? 2 : 0
        border.color: "#ff6d91"

        Label {
            anchors.centerIn: parent
            text: root.tinyControls ? "X" : "CANCEL"
            color: "#ff6d91"
            font.bold: true
            font.pixelSize: 9
            style: Text.Outline
            styleColor: "#f0000000"
        }

        MouseArea {
            id: cancelMouse
            anchors.fill: parent
            onClicked: root.customPadPage.cancelEdit()
        }
    }

    Rectangle {
        id: minimizeButton
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        width: root.tinyControls ? 28 : 56
        radius: 7
        color: minimizeMouse.pressed
               ? Qt.alpha(root.appearanceStore.primary, 0.24) : "transparent"
        border.width: root.appearanceStore.keyBordersVisible ? 2 : 0
        border.color: root.appearanceStore.primary

        Label {
            anchors.centerIn: parent
            text: root.tinyControls ? "M" : "MIN"
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
}
