// SPDX-FileCopyrightText: 2026 AnicetusCer
// SPDX-License-Identifier: GPL-3.0-or-later

import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Item {
    id: root

    property var pageData: ({controller:null})

    readonly property var controller: pageData.controller
    readonly property var slotChoices: [
        {index:0, controller: controller},
        {index:1, controller: controller},
        {index:2, controller: controller},
        {index:3, controller: controller},
        {index:4, controller: controller},
        {index:5, controller: controller},
        {index:6, controller: controller},
        {index:7, controller: controller},
        {index:8, controller: controller}
    ]

    ColumnLayout {
        anchors.fill: parent
        spacing: 3
        visible: !root.controller.pickerOpen

        RowLayout {
            Layout.fillWidth: true
            Layout.minimumHeight: 14
            Layout.preferredHeight: 16
            Layout.maximumHeight: 18
            spacing: 4

            Label {
                Layout.fillWidth: true
                text: root.controller.customKeyStore.error.length > 0
                      ? root.controller.customKeyStore.error
                      : root.controller.editMode ? "SELECT A SLOT" : "9 CUSTOM KEYS"
                color: root.controller.customKeyStore.error.length > 0
                       ? "#ff6d91" : root.controller.appearanceStore.primary
                font.pixelSize: 9
                font.bold: true
                style: Text.Outline
                styleColor: "#f0000000"
            }

            KeyCap {
                Layout.preferredWidth: 78
                Layout.preferredHeight: 16
                visible: root.controller.editMode
                compact: true
                showBorders: root.controller.appearanceStore.keyBordersVisible
                keyLabel: "CANCEL"
                accent: "#ff6d91"
                toolTipText: "Discard assignment changes"
                onClicked: root.controller.cancelEditing()
            }

            KeyCap {
                Layout.preferredWidth: 54
                Layout.preferredHeight: 16
                compact: true
                showBorders: root.controller.appearanceStore.keyBordersVisible
                keyLabel: root.controller.editMode ? "SAVE" : "SET"
                accent: root.controller.editMode
                        ? "#72ff9f" : root.controller.appearanceStore.secondary
                toolTipText: root.controller.editMode
                             ? "Save all custom-key assignments"
                             : "Enter custom-key assignment mode"
                onClicked: root.controller.toggleSetMode()
            }
        }

        GridLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            Layout.minimumHeight: 108
            Layout.preferredHeight: 132
            columns: 3
            rowSpacing: 5
            columnSpacing: 5

            Repeater {
                model: root.slotChoices

                KeyCap {
                    id: customSlotKey

                    required property var modelData

                    readonly property int slotIndex: modelData.index
                    readonly property var controller: modelData.controller
                    property var assignment: controller.editMode
                                             ? controller.draftAssignments[slotIndex]
                                             : controller.customKeyStore.assignments[slotIndex]

                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    showBorders: customSlotKey.controller.appearanceStore.keyBordersVisible
                    keyLabel: customSlotKey.assignment && customSlotKey.assignment.label
                              ? customSlotKey.assignment.label : "＋"
                    keyIcon: customSlotKey.assignment && customSlotKey.assignment.icon
                             ? customSlotKey.assignment.icon : ""
                    accent: customSlotKey.controller.editMode
                            && customSlotKey.controller.selectedSlot === customSlotKey.slotIndex
                            ? customSlotKey.controller.appearanceStore.secondary
                            : customSlotKey.controller.appearanceStore.primary
                    toolTipText: customSlotKey.controller.editMode
                                 ? "Assign slot " + (customSlotKey.slotIndex + 1) + "; hold to clear"
                                 : (customSlotKey.assignment
                                    ? customSlotKey.assignment.description : "Unassigned")
                    toolTipIcon: customSlotKey.assignment && customSlotKey.assignment.icon
                                 ? customSlotKey.assignment.icon : ""
                    repeatEnabled: !customSlotKey.controller.editMode
                                   && customSlotKey.controller.repeatableAssignment(customSlotKey.assignment)
                    onClicked: {
                        if (customSlotKey.controller.editMode) {
                            customSlotKey.controller.selectedSlot = customSlotKey.slotIndex
                            customSlotKey.controller.pickerOpen = true
                            customSlotKey.controller.openCustomKeyPicker()
                        } else {
                            customSlotKey.controller.triggerAssignment(customSlotKey.assignment)
                        }
                    }
                    onPressAndHold: {
                        if (customSlotKey.controller.editMode)
                            customSlotKey.controller.clearSlot(customSlotKey.slotIndex)
                    }
                }
            }
        }
    }
}
