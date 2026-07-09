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
        {index:8, controller: controller},
        {index:9, controller: controller},
        {index:10, controller: controller},
        {index:11, controller: controller},
        {index:12, controller: controller},
        {index:13, controller: controller},
        {index:14, controller: controller},
        {index:15, controller: controller}
    ]

    ColumnLayout {
        anchors.fill: parent
        spacing: 3
        visible: root.hasController && !root.controller.pickerOpen

        Item {
            Layout.fillWidth: true
            Layout.minimumHeight: 14
            Layout.preferredHeight: 16
            Layout.maximumHeight: 18

            Label {
                anchors.left: parent.left
                anchors.right: editControls.left
                anchors.rightMargin: 4
                anchors.verticalCenter: parent.verticalCenter
                text: !root.hasController ? ""
                      : root.controller.customKeyStore.error.length > 0
                      ? root.controller.customKeyStore.error
                      : ""
                color: root.hasController && root.controller.customKeyStore.error.length > 0
                       ? "#ff6d91"
                       : root.hasController ? root.controller.appearanceStore.primary : "#48f3ff"
                font.pixelSize: 9
                font.bold: true
                style: Text.Outline
                styleColor: "#f0000000"
                elide: Text.ElideRight
            }

            Row {
                id: editControls
                anchors.right: parent.right
                anchors.top: parent.top
                anchors.bottom: parent.bottom
                spacing: 3

                KeyCap {
                    width: visible ? 24 : 0
                    height: parent.height
                    visible: root.hasController && root.controller.editMode
                    enabled: root.hasController && root.controller.selectedSlot > 0
                    compact: true
                    showBorders: root.hasController ? root.controller.appearanceStore.keyBordersVisible : true
                    keyLabel: "←"
                    accent: enabled ? root.controller.appearanceStore.secondary : "#666666"
                    toolTipText: "Move the selected custom slot left"
                    onClicked: {
                        if (root.hasController) root.controller.moveSelectedSlot(-1)
                    }
                }

                KeyCap {
                    width: visible ? 24 : 0
                    height: parent.height
                    visible: root.hasController && root.controller.editMode
                    enabled: root.hasController
                             && root.controller.selectedSlot >= 0
                             && root.controller.selectedSlot < root.controller.draftAssignments.length - 1
                    compact: true
                    showBorders: root.hasController ? root.controller.appearanceStore.keyBordersVisible : true
                    keyLabel: "→"
                    accent: enabled ? root.controller.appearanceStore.secondary : "#666666"
                    toolTipText: "Move the selected custom slot right"
                    onClicked: {
                        if (root.hasController) root.controller.moveSelectedSlot(1)
                    }
                }

                KeyCap {
                    width: visible ? 58 : 0
                    height: parent.height
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
                    width: root.hasController && root.controller.editMode ? 48 : 76
                    height: parent.height
                    visible: root.hasController
                    compact: true
                    showBorders: root.hasController ? root.controller.appearanceStore.keyBordersVisible : true
                    keyLabel: root.hasController && root.controller.editMode ? "SAVE" : "CUSTOMISE"
                    accent: root.hasController && root.controller.editMode
                            ? "#72ff9f"
                            : root.hasController ? root.controller.appearanceStore.secondary : "#ef64ff"
                    toolTipText: root.hasController && root.controller.editMode
                                 ? "Save all custom-key assignments"
                                 : "Enter custom-key assignment and ordering mode"
                    onClicked: {
                        if (root.hasController) root.controller.toggleSetMode()
                    }
                }
            }
        }

        GridLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            Layout.minimumHeight: 108
            Layout.preferredHeight: 132
            columns: 4
            rowSpacing: 3
            columnSpacing: 3

            Repeater {
                model: root.hasController ? root.slotChoices : []

                Item {
                    id: customSlotCell

                    required property var modelData

                    readonly property int slotIndex: modelData.index
                    readonly property var controller: modelData.controller
                    readonly property bool hasController: controller !== null && controller !== undefined
                    property var assignment: customSlotCell.hasController && controller.editMode
                                             ? controller.draftAssignments[slotIndex]
                                             : customSlotCell.hasController
                                               ? controller.customKeyStore.assignments[slotIndex] : null

                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    Layout.minimumWidth: 0
                    Layout.minimumHeight: 0

                    KeyCap {
                        id: customSlotKey

                        anchors.fill: parent
                        compact: true
                        showBorders: customSlotCell.hasController
                                     ? customSlotCell.controller.appearanceStore.keyBordersVisible : true
                        keyLabel: customSlotCell.assignment && customSlotCell.assignment.label
                                  ? customSlotCell.assignment.label : "＋"
                        keyIcon: customSlotCell.assignment && customSlotCell.assignment.icon
                                 ? customSlotCell.assignment.icon : ""
                        accent: customSlotCell.hasController
                                && customSlotCell.controller.editMode
                                && customSlotCell.controller.selectedSlot === customSlotCell.slotIndex
                                ? customSlotCell.controller.appearanceStore.secondary
                                : customSlotCell.hasController
                                  ? customSlotCell.controller.appearanceStore.primary : "#48f3ff"
                        toolTipText: customSlotCell.hasController && customSlotCell.controller.editMode
                                     ? customSlotCell.controller.selectedSlot === customSlotCell.slotIndex
                                       ? "Tap again to assign slot " + (customSlotCell.slotIndex + 1)
                                         + "; hold to clear"
                                       : "Select slot " + (customSlotCell.slotIndex + 1)
                                         + " for moving or assignment"
                                     : (customSlotCell.assignment
                                        ? customSlotCell.assignment.description : "Unassigned")
                        toolTipIcon: customSlotCell.assignment && customSlotCell.assignment.icon
                                     ? customSlotCell.assignment.icon : ""
                        repeatEnabled: customSlotCell.hasController
                                       && !customSlotCell.controller.editMode
                                       && customSlotCell.controller.repeatableAssignment(customSlotCell.assignment)
                        onClicked: {
                            if (!customSlotCell.hasController) return
                            if (customSlotCell.controller.editMode) {
                                if (customSlotCell.controller.selectedSlot === customSlotCell.slotIndex) {
                                    customSlotCell.controller.pickerOpen = true
                                    customSlotCell.controller.openCustomKeyPicker()
                                } else {
                                    customSlotCell.controller.selectedSlot = customSlotCell.slotIndex
                                }
                            } else {
                                customSlotCell.controller.triggerAssignment(customSlotCell.assignment)
                            }
                        }
                        onPressAndHold: {
                            if (customSlotCell.hasController && customSlotCell.controller.editMode)
                                customSlotCell.controller.clearSlot(customSlotCell.slotIndex)
                        }
                    }
                }
            }
        }
    }
}
