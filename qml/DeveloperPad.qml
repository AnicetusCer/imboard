// SPDX-FileCopyrightText: 2026 AnicetusCer
// SPDX-License-Identifier: GPL-3.0-or-later

import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Item {
    id: root

    required property var appearanceStore
    required property var customKeyStore
    required property var inputBackend
    required property var modifierSource

    property bool editMode: false
    property bool pickerOpen: false
    property int selectedSlot: -1
    property int currentPageIndex: Math.max(
        0, Math.min(appearanceStore.developerPadPageIndex, pages.length - 1))
    property var draftAssignments: []
    property string pickerCategory: "all"

    onCurrentPageIndexChanged:
        appearanceStore.setDeveloperPadPageIndex(currentPageIndex)

    DeveloperPadCatalog {
        id: catalog
        controller: root
    }

    readonly property var pickerCategories: catalog.pickerCategories
    readonly property var pages: catalog.pages
    readonly property var pickerKeys: catalog.pickerKeys
    // Filtering and action dispatch.
    readonly property var filteredPickerKeys: pickerKeys.filter(function(key) {
        return root.pickerCategory === "all"
                || root.categoryForKey(key) === root.pickerCategory
    })
    readonly property var filteredPickerChoices: filteredPickerKeys.map(function(key) {
        return {key:key, controller: root}
    })
    readonly property var pickerCategoryChoices: pickerCategories.map(function(category) {
        return {category:category, controller: root}
    })
    readonly property var pageDotChoices: [
        {index:0, controller: root},
        {index:1, controller: root},
        {index:2, controller: root},
        {index:3, controller: root},
        {index:4, controller: root},
        {index:5, controller: root}
    ]

    function categoryForKey(key) {
        if (key.type === "chord") return "combos"
        if (key.category === "emoji") return "emoji"
        if (key.category === "token") return "dev"
        if (key.type === "text") return "symbols"
        if (key.value.length === 1) return "abc"
        if (key.value.length > 1 && key.value.charAt(0) === "F"
                && !isNaN(Number(key.value.substring(1)))) return "fkeys"
        return "nav"
    }

    function repeatableAction(action) {
        return action[1] === "key" && modifierSource.repeatableKey(action[2])
               && !modifierSource.repeatBlockingModifierActive()
    }

    function repeatableAssignment(assignment) {
        return assignment && assignment.type === "key"
               && modifierSource.repeatableKey(assignment.value)
               && !modifierSource.repeatBlockingModifierActive()
    }

    function activeKeyModifiers() {
        const modifiers = []
        if (modifierSource.controlHeld) modifiers.push("Ctrl")
        if (modifierSource.altHeld) modifiers.push("Alt")
        if (modifierSource.metaHeld) modifiers.push("Meta")
        if (modifierSource.shifted) modifiers.push("Shift")
        return modifiers
    }

    function sendKeyWithActiveModifiers(value) {
        const modifiers = activeKeyModifiers()
        if (modifiers.length > 0) inputBackend.sendChord(modifiers, value)
        else inputBackend.sendKey(value)
        modifierSource.clearOneShotShift()
    }

    function trigger(action) {
        if (action[1] === "text") inputBackend.sendText(action[2])
        else if (action[1] === "key") sendKeyWithActiveModifiers(action[2])
        else if (action[1] === "chord") inputBackend.sendChord(action[2], action[3])
    }

    function triggerAssignment(assignment) {
        if (!assignment || !assignment.type) return
        if (assignment.type === "text") inputBackend.sendText(assignment.value)
        else if (assignment.type === "key") sendKeyWithActiveModifiers(assignment.value)
        else if (assignment.type === "chord")
            inputBackend.sendChord(assignment.modifiers, assignment.key)
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

    function toggleSetMode() {
        if (!editMode) {
            draftAssignments = copyAssignments()
            editMode = true
            pickerOpen = false
            selectedSlot = -1
            return
        }
        if (customKeyStore.commit(draftAssignments)) {
            editMode = false
            pickerOpen = false
            selectedSlot = -1
        }
    }

    function cancelEditing() {
        draftAssignments = []
        editMode = false
        pickerOpen = false
        selectedSlot = -1
    }

    function chooseKey(key) {
        if (selectedSlot < 0) return
        const next = draftAssignments.slice()
        next[selectedSlot] = {label:key.label, type:key.type, value:key.value,
                              modifiers:key.modifiers, key:key.key,
                              icon:key.icon,
                              description:key.description}
        draftAssignments = next
        customKeyPicker.close()
        pickerOpen = false
    }

    function openCustomKeyPicker() {
        customKeyPicker.open()
    }

    function setPageIndex(index) {
        currentPageIndex = index
    }

    function clearSlot(slot) {
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
        if (target < 0 || target >= draftAssignments.length) return
        const next = draftAssignments.slice()
        const item = next[selectedSlot]
        next[selectedSlot] = next[target]
        next[target] = item
        draftAssignments = next
        selectedSlot = target
    }

    CustomKeyPickerPopup {
        id: customKeyPicker
        appearanceStore: root.appearanceStore
        controller: root
    }

    ColumnLayout {
        anchors.fill: parent
        spacing: 4

        RowLayout {
            Layout.fillWidth: true
            Layout.preferredHeight: 24
            Label {
                Layout.fillWidth: true
                text: root.pickerOpen
                      ? "CUSTOM / PICK KEY" : root.pages[root.currentPageIndex].title
                color: root.appearanceStore.secondary
                font.bold: true
                style: Text.Outline
                styleColor: "#f0000000"
            }

            Row {
                spacing: 6

                Repeater {
                    model: root.pageDotChoices

                    Rectangle {
                        id: pageIndicatorDot

                        required property var modelData

                        readonly property int pageIndex: modelData.index
                        readonly property var controller: modelData.controller

                        width: 9
                        height: 9
                        radius: width / 2
                        color: pageIndicatorDot.pageIndex === pageIndicatorDot.controller.currentPageIndex
                               ? pageIndicatorDot.controller.appearanceStore.secondary : "transparent"
                        border.width: 1
                        border.color: pageIndicatorDot.pageIndex === pageIndicatorDot.controller.currentPageIndex
                                      ? "#ffffff" : pageIndicatorDot.controller.appearanceStore.primary

                        MouseArea {
                            anchors.fill: parent
                            enabled: !pageIndicatorDot.controller.pickerOpen
                            onClicked: pageIndicatorDot.controller.setPageIndex(pageIndicatorDot.pageIndex)
                        }
                    }
                }
            }
        }

        SwipeView {
            id: view
            Layout.fillWidth: true
            Layout.fillHeight: true
            clip: true
            interactive: !root.pickerOpen
            currentIndex: root.currentPageIndex
            onCurrentIndexChanged: root.currentPageIndex = view.currentIndex

            Repeater {
                model: root.pages
                Loader {
                    required property var modelData
                    property var pageData: modelData
                    source: pageData.title === "CUSTOM"
                            ? "DeveloperCustomPage.qml" : "DeveloperStandardPage.qml"
                    onLoaded: item.pageData = pageData
                }
            }
        }
    }
}
