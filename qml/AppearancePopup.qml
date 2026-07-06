// SPDX-FileCopyrightText: 2026 AnicetusCer
// SPDX-License-Identifier: GPL-3.0-or-later

pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Popup {
    id: root

    required property var appearanceStore
    readonly property var presets: [
        {id: "cyber", label: "CYBER", primary: "#48f3ff", secondary: "#ef64ff"},
        {id: "matrix", label: "MATRIX", primary: "#65ff70", secondary: "#c6ff4a"},
        {id: "amber", label: "AMBER", primary: "#ffb43b", secondary: "#fff06a"},
        {id: "ice", label: "ICE", primary: "#69a7ff", secondary: "#e8f3ff"},
        {id: "violet", label: "VIOLET", primary: "#b77cff", secondary: "#ff67d4"},
        {id: "red", label: "RED", primary: "#ff3b4f", secondary: "#ff8a65"}
    ]
    property real renderedOptionHeight: 62

    objectName: "appearancePopup"
    x: Math.round((parent.width - width) / 2)
    y: Math.round((parent.height - height) / 2)
    width: Math.min(590, parent.width - 40)
    height: Math.min(250, parent.height - 30)
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
                text: "IMBOARD APPEARANCE"
                color: root.appearanceStore.primary
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
            Layout.minimumHeight: 58
            Layout.preferredHeight: 62
            columns: 6
            columnSpacing: 5

            Repeater {
                model: root.presets
                Rectangle {
                    id: presetOption
                    required property var modelData
                    objectName: "stylePreset_" + modelData.id
                    implicitHeight: 58
                    implicitWidth: 76
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    radius: 8
                    color: root.appearanceStore.scheme === modelData.id
                           ? "#28ffffff" : "transparent"
                    border.width: root.appearanceStore.scheme === modelData.id ? 4 : 2
                    border.color: modelData.primary

                    Rectangle {
                        anchors.fill: parent
                        anchors.margins: 5
                        radius: 4
                        color: "transparent"
                        border.width: 2
                        border.color: presetOption.modelData.secondary
                    }
                    Label {
                        anchors.centerIn: parent
                        text: presetOption.modelData.label
                        color: presetOption.modelData.primary
                        font.bold: true
                        font.pixelSize: 9
                        style: Text.Outline
                        styleColor: "#f0000000"
                    }
                    MouseArea {
                        anchors.fill: parent
                        onClicked: root.appearanceStore.selectScheme(
                                       presetOption.modelData.id)
                    }
                }
            }
        }

        RowLayout {
            Layout.fillWidth: true
            Layout.preferredHeight: 34
            Label {
                text: "BACKGROUND"
                color: root.appearanceStore.secondary
                font.bold: true
                font.pixelSize: 10
            }
            Slider {
                Layout.fillWidth: true
                from: 0.0
                to: 1.0
                value: root.appearanceStore.backdropOpacity
                onMoved: root.appearanceStore.setBackdropOpacity(value)
            }
            Label {
                Layout.preferredWidth: 38
                horizontalAlignment: Text.AlignRight
                text: Math.round(root.appearanceStore.backdropOpacity * 100) + "%"
                color: root.appearanceStore.primary
                font.bold: true
                font.pixelSize: 10
            }
        }

        RowLayout {
            Layout.fillWidth: true
            Layout.preferredHeight: 32
            Label {
                Layout.fillWidth: true
                text: "OUTER LINES"
                color: root.appearanceStore.secondary
                font.bold: true
                font.pixelSize: 10
            }
            KeyCap {
                Layout.preferredWidth: 70
                Layout.fillHeight: true
                compact: true
                showBorders: root.appearanceStore.keyBordersVisible
                keyLabel: root.appearanceStore.frameBordersVisible ? "ON" : "OFF"
                accent: root.appearanceStore.frameBordersVisible
                        ? "#72ff9f" : root.appearanceStore.primary
                toolTipText: "Show or hide the keyboard frame and panel border lines"
                onClicked: root.appearanceStore.toggleFrameBorders()
            }
            Label {
                Layout.fillWidth: true
                text: "KEY LINES"
                color: root.appearanceStore.secondary
                font.bold: true
                font.pixelSize: 10
            }
            KeyCap {
                Layout.preferredWidth: 70
                Layout.fillHeight: true
                compact: true
                showBorders: root.appearanceStore.keyBordersVisible
                keyLabel: root.appearanceStore.keyBordersVisible ? "ON" : "OFF"
                accent: root.appearanceStore.keyBordersVisible
                        ? "#72ff9f" : root.appearanceStore.primary
                toolTipText: "Show or hide key/button border lines"
                onClicked: root.appearanceStore.toggleKeyBorders()
            }
        }
    }
}
