// SPDX-FileCopyrightText: 2026 AnicetusCer
// SPDX-License-Identifier: GPL-3.0-or-later

import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Item {
    id: root

    property var pageData: ({controller:null})

    readonly property var controller: pageData.controller
    readonly property bool hasController: controller !== null && controller !== undefined
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
        visible: root.hasController && !root.controller.pickerOpen

        RowLayout {
            Layout.fillWidth: true
            Layout.minimumHeight: 14
            Layout.preferredHeight: 16
            Layout.maximumHeight: 18
            spacing: 4

            Label {
                Layout.fillWidth: true
                text: !root.hasController ? ""
                      : root.controller.customKeyStore.error.length > 0
                      ? root.controller.customKeyStore.error
                      : root.controller.editMode ? "SELECT A SLOT" : "9 CUSTOM KEYS"
                color: root.hasController && root.controller.customKeyStore.error.length > 0
                       ? "#ff6d91"
                       : root.hasController ? root.controller.appearanceStore.primary : "#48f3ff"
                font.pixelSize: 9
                font.bold: true
                style: Text.Outline
                styleColor: "#f0000000"
            }

            KeyCap {
                Layout.preferredWidth: 78
                Layout.preferredHeight: 16
                visible: root.hasController && root.controller.editMode
                compact: true
                showBorders: root.hasController ? root.controller.appearanceStore.keyBordersVisible : true
                keyLabel: "CANCEL"
                accent: "#ff6d91"
                toolTipText: "Discard assignment changes"
                onClicked: {
                    if (root.hasController) root.controller.cancelEditing()
                }
            }

            KeyCap {
                Layout.preferredWidth: 54
                Layout.preferredHeight: 16
                visible: root.hasController
                compact: true
                showBorders: root.hasController ? root.controller.appearanceStore.keyBordersVisible : true
                keyLabel: root.hasController && root.controller.editMode ? "SAVE" : "SET"
                accent: root.hasController && root.controller.editMode
                        ? "#72ff9f"
                        : root.hasController ? root.controller.appearanceStore.secondary : "#ef64ff"
                toolTipText: root.hasController && root.controller.editMode
                             ? "Save all custom-key assignments"
                             : "Enter custom-key assignment mode"
                onClicked: {
                    if (root.hasController) root.controller.toggleSetMode()
                }
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
                model: root.hasController ? root.slotChoices : []

                KeyCap {
                    id: customSlotKey

                    required property var modelData

                    readonly property int slotIndex: modelData.index
                    readonly property var controller: modelData.controller
                    readonly property bool hasController: controller !== null && controller !== undefined
                    property var assignment: customSlotKey.hasController && controller.editMode
                                             ? controller.draftAssignments[slotIndex]
                                             : customSlotKey.hasController
                                               ? controller.customKeyStore.assignments[slotIndex] : null

                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    showBorders: customSlotKey.hasController
                                 ? customSlotKey.controller.appearanceStore.keyBordersVisible : true
                    keyLabel: customSlotKey.assignment && customSlotKey.assignment.label
                              ? customSlotKey.assignment.label : "＋"
                    keyIcon: customSlotKey.assignment && customSlotKey.assignment.icon
                             ? customSlotKey.assignment.icon : ""
                    accent: customSlotKey.hasController
                            && customSlotKey.controller.editMode
                            && customSlotKey.controller.selectedSlot === customSlotKey.slotIndex
                            ? customSlotKey.controller.appearanceStore.secondary
                            : customSlotKey.hasController
                              ? customSlotKey.controller.appearanceStore.primary : "#48f3ff"
                    toolTipText: customSlotKey.hasController && customSlotKey.controller.editMode
                                 ? "Assign slot " + (customSlotKey.slotIndex + 1) + "; hold to clear"
                                 : (customSlotKey.assignment
                                    ? customSlotKey.assignment.description : "Unassigned")
                    toolTipIcon: customSlotKey.assignment && customSlotKey.assignment.icon
                                 ? customSlotKey.assignment.icon : ""
                    repeatEnabled: customSlotKey.hasController
                                   && !customSlotKey.controller.editMode
                                   && customSlotKey.controller.repeatableAssignment(customSlotKey.assignment)
                    onClicked: {
                        if (!customSlotKey.hasController) return
                        if (customSlotKey.controller.editMode) {
                            customSlotKey.controller.selectedSlot = customSlotKey.slotIndex
                            customSlotKey.controller.pickerOpen = true
                            customSlotKey.controller.openCustomKeyPicker()
                        } else {
                            customSlotKey.controller.triggerAssignment(customSlotKey.assignment)
                        }
                    }
                    onPressAndHold: {
                        if (customSlotKey.hasController && customSlotKey.controller.editMode)
                            customSlotKey.controller.clearSlot(customSlotKey.slotIndex)
                    }
                }
            }
        }
    }
}
