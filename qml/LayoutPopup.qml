// SPDX-FileCopyrightText: 2026 AnicetusCer
// SPDX-License-Identifier: GPL-3.0-or-later

pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Popup {
    id: root

    required property var appearanceStore
    required property var keyboardLayoutStore
    property real renderedOptionHeight: 76

    objectName: "layoutPopup"
    x: Math.round((parent.width - width) / 2)
    y: Math.round((parent.height - height) / 2)
    width: Math.min(500, parent.width - 40)
    height: Math.min(180, parent.height - 30)
    padding: 12
    modal: true
    dim: false
    closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutside

    background: Rectangle {
        radius: 12
        color: "#f20a1020"
        border.width: 4
        border.color: root.appearanceStore.primary

        Rectangle {
            anchors.fill: parent
            anchors.margins: 5
            radius: 8
            color: "transparent"
            border.width: 2
            border.color: root.appearanceStore.secondary
        }
    }

    contentItem: ColumnLayout {
        spacing: 8

        RowLayout {
            Layout.fillWidth: true
            Layout.preferredHeight: 25
            Label {
                Layout.fillWidth: true
                text: root.keyboardLayoutStore.error.length > 0
                      ? root.keyboardLayoutStore.error.toUpperCase()
                      : "REGIONAL KEYBOARD LAYOUT"
                color: root.keyboardLayoutStore.error.length > 0
                       ? "#ff6d91" : root.appearanceStore.primary
                font.bold: true
                font.pixelSize: 11
                style: Text.Outline
                styleColor: "#f0000000"
            }
            KeyCap {
                Layout.preferredWidth: 54
                Layout.fillHeight: true
                compact: true
                showBorders: root.appearanceStore.keyBordersVisible
                keyLabel: "CLOSE"
                accent: root.appearanceStore.secondary
                onClicked: root.close()
            }
        }

        GridLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            Layout.minimumHeight: 70
            Layout.preferredHeight: 76
            columns: 2
            columnSpacing: 8
            rowSpacing: 8

            Repeater {
                model: root.keyboardLayoutStore.availableLayouts
                Rectangle {
                    id: layoutOption
                    required property var modelData
                    objectName: "layoutChoice_" + modelData.id
                    implicitHeight: 70
                    implicitWidth: 190
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    radius: 9
                    color: root.keyboardLayoutStore.layoutId === modelData.id
                           ? "#28ffffff" : "transparent"
                    border.width: root.keyboardLayoutStore.layoutId === modelData.id ? 4 : 2
                    border.color: root.keyboardLayoutStore.layoutId === modelData.id
                                  ? root.appearanceStore.secondary
                                  : root.appearanceStore.primary

                    Column {
                        anchors.centerIn: parent
                        spacing: 2
                        Label {
                            anchors.horizontalCenter: parent.horizontalCenter
                            text: layoutOption.modelData.id.toUpperCase()
                            color: root.appearanceStore.primary
                            font.bold: true
                            font.pixelSize: 14
                            style: Text.Outline
                            styleColor: "#f0000000"
                        }
                        Label {
                            anchors.horizontalCenter: parent.horizontalCenter
                            text: layoutOption.modelData.name
                            color: root.appearanceStore.secondary
                            font.pixelSize: 10
                            style: Text.Outline
                            styleColor: "#f0000000"
                        }
                    }
                    MouseArea {
                        anchors.fill: parent
                        onClicked: root.keyboardLayoutStore.selectLayout(
                                       layoutOption.modelData.id)
                    }
                }
            }
        }
    }
}
