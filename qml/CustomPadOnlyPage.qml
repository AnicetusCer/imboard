// SPDX-FileCopyrightText: 2026 AnicetusCer
// SPDX-License-Identifier: GPL-3.0-or-later

pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts

Item {
    id: root

    required property var appearanceStore
    required property var customKeyStore
    required property var inputBackend

    property bool editMode: false
    property int selectedSlot: -1
    property var draftAssignments: []

    readonly property bool editorMode: editMode
    readonly property int keyCount: Math.max(1, Math.min(16, appearanceStore.customPadKeyCount))
    readonly property int automaticColumns: keyCount <= 1 ? 1 : keyCount <= 4 ? 2 : keyCount <= 9 ? 3 : 4
    readonly property int columnCount: appearanceStore.customPadColumns > 0
                                       ? Math.min(appearanceStore.customPadColumns, keyCount)
                                       : automaticColumns
    readonly property var slotChoices: [
        {index:0, controller: root},
        {index:1, controller: root},
        {index:2, controller: root},
        {index:3, controller: root},
        {index:4, controller: root},
        {index:5, controller: root},
        {index:6, controller: root},
        {index:7, controller: root},
        {index:8, controller: root},
        {index:9, controller: root},
        {index:10, controller: root},
        {index:11, controller: root},
        {index:12, controller: root},
        {index:13, controller: root},
        {index:14, controller: root},
        {index:15, controller: root}
    ]

    signal assignmentPickerRequested

    function repeatableKey(value) {
        return value === "Backspace" || value === "Delete"
               || value === "Left" || value === "Right"
               || value === "Up" || value === "Down"
               || value === "Home" || value === "End"
               || value === "PageUp" || value === "PageDown"
    }

    function triggerAssignment(assignment) {
        if (!assignment || !assignment.type) return
        if (assignment.type === "text") root.inputBackend.sendText(assignment.value)
        else if (assignment.type === "key") root.inputBackend.sendKey(assignment.value)
        else if (assignment.type === "chord")
            root.inputBackend.sendChord(assignment.modifiers, assignment.key)
    }

    function copyAssignments() {
        const copy = []
        for (let index = 0; index < customKeyStore.assignments.length; ++index) {
            const item = customKeyStore.assignments[index]
            copy.push({label:item.label, type:item.type, value:item.value,
                       modifiers:item.modifiers, key:item.key,
                       icon:item.icon,
                       description:item.description})
        }
        return copy
    }

    function beginEdit() {
        draftAssignments = copyAssignments()
        selectedSlot = -1
        editMode = true
    }

    function finishEdit() {
        if (customKeyStore.commit(draftAssignments)) {
            editMode = false
            selectedSlot = -1
            draftAssignments = []
            return true
        }
        return false
    }

    function cancelEdit() {
        draftAssignments = []
        selectedSlot = -1
        editMode = false
    }

    function finishEditorMode() {
        if (editMode) return finishEdit()
        return true
    }

    function clearSlot(slot) {
        if (!editMode || slot < 0 || slot >= keyCount) return
        const next = draftAssignments.slice()
        next[slot] = {
            label: "",
            type: "",
            value: "",
            modifiers: [],
            key: "",
            icon: "",
            description: "Unassigned"
        }
        draftAssignments = next
        selectedSlot = slot
    }

    function moveSelectedSlot(delta) {
        if (selectedSlot < 0) return
        const target = selectedSlot + delta
        if (target < 0 || target >= keyCount) return
        const next = draftAssignments.slice()
        const item = next[selectedSlot]
        next[selectedSlot] = next[target]
        next[target] = item
        draftAssignments = next
        selectedSlot = target
    }

    function chooseSlot(slot) {
        if (editMode) {
            if (selectedSlot === slot) assignmentPickerRequested()
            else selectedSlot = slot
        }
    }

    QtObject {
        id: modifierStub

        property bool controlHeld: false
        property bool altHeld: false
        property bool metaHeld: false
        property bool shifted: false

        function repeatBlockingModifierActive() { return false }
        function repeatableKey(value) { return root.repeatableKey(value) }
        function clearOneShotShift() {}
    }

    Loader {
        id: editorLoader
        active: root.editMode
        sourceComponent: DeveloperPad {
            id: editorPad
            property bool readyForDraftSync: false

            visible: false
            width: 0
            height: 0
            appearanceStore: root.appearanceStore
            customKeyStore: root.customKeyStore
            inputBackend: root.inputBackend
            modifierSource: modifierStub

            Component.onCompleted: {
                editMode = true
                draftAssignments = root.draftAssignments
                selectedSlot = root.selectedSlot
                readyForDraftSync = true
            }
            onDraftAssignmentsChanged: {
                if (readyForDraftSync)
                    root.draftAssignments = draftAssignments
            }
            onSelectedSlotChanged: root.selectedSlot = selectedSlot

            Connections {
                target: root
                function onAssignmentPickerRequested() {
                    editorPad.readyForDraftSync = false
                    editorPad.selectedSlot = root.selectedSlot
                    editorPad.draftAssignments = root.draftAssignments
                    editorPad.readyForDraftSync = true
                    editorPad.pickerOpen = true
                    editorPad.openCustomKeyPicker()
                }
            }
        }
    }

    GridLayout {
        objectName: "customPadOnlyGrid"
        anchors.fill: parent
        columns: root.columnCount
        rowSpacing: 6
        columnSpacing: 6

        Repeater {
            model: root.slotChoices.slice(0, root.keyCount)

            KeyCap {
                id: customPadKey

                required property var modelData

                readonly property int slotIndex: modelData.index
                readonly property var controller: modelData.controller
                property var assignment: customPadKey.controller.editorMode
                                         ? customPadKey.controller.draftAssignments[slotIndex]
                                         : customPadKey.controller.customKeyStore.assignments[slotIndex]

                Layout.fillWidth: true
                Layout.fillHeight: true
                Layout.minimumWidth: 0
                Layout.minimumHeight: 0
                showBorders: customPadKey.controller.appearanceStore.keyBordersVisible
                keyLabel: customPadKey.assignment && customPadKey.assignment.label
                          ? customPadKey.assignment.label : "+"
                keyIcon: customPadKey.assignment && customPadKey.assignment.icon
                         ? customPadKey.assignment.icon : ""
                accent: customPadKey.assignment && customPadKey.assignment.type
                        ? customPadKey.controller.editorMode
                          && customPadKey.controller.selectedSlot === customPadKey.slotIndex
                          ? customPadKey.controller.appearanceStore.secondary
                          : customPadKey.controller.appearanceStore.primary
                        : "#ff6d91"
                toolTipText: customPadKey.controller.editMode
                             ? customPadKey.controller.selectedSlot === customPadKey.slotIndex
                               ? "Tap again to assign slot " + (customPadKey.slotIndex + 1)
                                 + "; hold to clear"
                               : "Select slot " + (customPadKey.slotIndex + 1)
                                 + " for moving or assignment"
                             : customPadKey.assignment && customPadKey.assignment.type
                               ? customPadKey.assignment.description
                               : "Unassigned; switch back to full mode to configure"
                toolTipIcon: customPadKey.assignment && customPadKey.assignment.icon
                             ? customPadKey.assignment.icon : ""
                repeatEnabled: customPadKey.assignment
                               && !customPadKey.controller.editorMode
                               && customPadKey.assignment.type === "key"
                               && customPadKey.controller.repeatableKey(customPadKey.assignment.value)
                onClicked: {
                    if (customPadKey.controller.editorMode)
                        customPadKey.controller.chooseSlot(customPadKey.slotIndex)
                    else
                        customPadKey.controller.triggerAssignment(customPadKey.assignment)
                }
                onPressAndHold: {
                    if (customPadKey.controller.editorMode)
                        customPadKey.controller.clearSlot(customPadKey.slotIndex)
                }
            }
        }
    }
}
