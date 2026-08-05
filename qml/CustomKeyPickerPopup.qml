// SPDX-FileCopyrightText: 2026 AnicetusCer
// SPDX-License-Identifier: GPL-3.0-or-later

pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Popup {
    id: root

    required property var appearanceStore
    required property var controller

    function resetGrid() {
        availableKeyGrid.positionViewAtBeginning()
    }

    objectName: "customKeyPicker"
    parent: Overlay.overlay
    x: Math.round((parent.width - width) / 2)
    y: Math.round((parent.height - height) / 2)
    width: Math.min(760, Math.max(160, parent.width - 24))
    height: Math.min(280, Math.max(90, parent.height - 24))
    padding: 10
    modal: true
    dim: false
    closePolicy: Popup.NoAutoClose
    onClosed: root.controller.pickerOpen = false

    background: Rectangle {
        radius: 12
        color: "#e00a1020"
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

    contentItem: Item {
        RowLayout {
            id: pickerHeader
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: parent.top
            height: Math.max(20, Math.min(26, parent.height * 0.18))

            Label {
                Layout.fillWidth: true
                text: "SELECT KEY FOR CUSTOM SLOT " + (root.controller.selectedSlot + 1)
                color: root.appearanceStore.secondary
                font.pixelSize: 11
                font.bold: true
                style: Text.Outline
                styleColor: "#f0000000"
            }

            KeyCap {
                Layout.preferredWidth: 58
                Layout.fillHeight: true
                keyLabel: "BACK"
                accent: "#ff6d91"
                compact: true
                showBorders: root.appearanceStore.keyBordersVisible
                toolTipText: "Return without changing this slot"
                onClicked: root.close()
            }
        }

        RowLayout {
            id: pickerCategoryBar
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: pickerHeader.bottom
            anchors.topMargin: 5
            height: Math.max(18, Math.min(22, parent.height * 0.16))
            spacing: 3

            Repeater {
                model: root.controller.pickerCategoryChoices

                KeyCap {
                    id: pickerCategoryKey
                    required property var modelData
                    readonly property var category: modelData.category
                    readonly property var padController: modelData.controller
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    compact: true
                    showBorders: pickerCategoryKey.padController.appearanceStore.keyBordersVisible
                    keyLabel: pickerCategoryKey.category.label
                    accent: pickerCategoryKey.padController.pickerCategory
                            === pickerCategoryKey.category.value
                            ? "#ffffff"
                            : pickerCategoryKey.padController.appearanceStore.primary
                    toolTipText: "Show "
                                 + pickerCategoryKey.category.label.toLowerCase()
                                 + " choices"
                    onClicked: {
                        pickerCategoryKey.padController.pickerCategory =
                            pickerCategoryKey.category.value
                        root.resetGrid()
                    }
                }
            }
        }

        GridView {
            id: availableKeyGrid
            objectName: "availableKeyGrid"
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: pickerCategoryBar.bottom
            anchors.bottom: parent.bottom
            anchors.topMargin: 6
            clip: true
            cellWidth: width / (width < 520 ? 4 : 8)
            cellHeight: width < 520 ? 38 : 48
            model: root.controller.filteredPickerChoices
            boundsBehavior: Flickable.StopAtBounds

            ScrollBar.vertical: ScrollBar {
                policy: ScrollBar.AlwaysOn
            }

            delegate: Item {
                id: availableKey
                required property var modelData
                readonly property var keyData: modelData.key
                readonly property var padController: modelData.controller
                width: availableKeyGrid.cellWidth
                height: availableKeyGrid.cellHeight

                KeyCap {
                    anchors.fill: parent
                    anchors.margins: 2
                    showBorders: availableKey.padController.appearanceStore.keyBordersVisible
                    keyLabel: availableKey.keyData.label
                    keyIcon: availableKey.keyData.icon || ""
                    accent: availableKey.keyData.type === "chord"
                            ? availableKey.padController.appearanceStore.secondary
                            : availableKey.keyData.category === "token" ? "#72ff9f"
                            : availableKey.keyData.category === "emoji" ? "#ffd166"
                            : availableKey.padController.appearanceStore.primary
                    toolTipText: availableKey.keyData.description
                    toolTipIcon: availableKey.keyData.icon || ""
                    onClicked: availableKey.padController.chooseKey(availableKey.keyData)
                }
            }
        }
    }
}
