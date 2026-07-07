// SPDX-FileCopyrightText: 2026 AnicetusCer
// SPDX-License-Identifier: GPL-3.0-or-later

pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts

Item {
    id: root

    required property var appearanceStore
    required property var inputBackend
    required property var layoutStore

    property bool shifted: false
    property bool shiftLocked: false
    property bool shiftLongPressConsumed: false
    property bool capsLocked: false
    property bool controlHeld: false
    property bool altHeld: false
    property bool metaHeld: false
    property var rows: layoutStore.rows

    function modifierActive(value) {
        if (value === "Shift") return shifted
        if (value === "Ctrl") return controlHeld
        if (value === "Alt") return altHeld
        if (value === "Meta") return metaHeld
        return false
    }

    function repeatBlockingModifierActive() {
        return controlHeld || altHeld || metaHeld
    }

    function repeatableKey(value) {
        return value === "Backspace" || value === "Delete"
               || value === "Left" || value === "Right"
               || value === "Up" || value === "Down"
               || value === "Home" || value === "End"
               || value === "PageUp" || value === "PageDown"
    }

    function toggleModifier(value) {
        if (value === "Shift") {
            if (shiftLocked) {
                shiftLocked = false
                shifted = false
            } else {
                shifted = !shifted
            }
        }
        else if (value === "Ctrl") controlHeld = !controlHeld
        else if (value === "Alt") altHeld = !altHeld
        else if (value === "Meta") metaHeld = !metaHeld
    }

    function holdModifier(value) {
        if (value !== "Shift") return
        shiftLocked = true
        shifted = true
        shiftLongPressConsumed = true
    }

    function clearOneShotShift() {
        if (!shiftLocked) shifted = false
    }

    function sendCharacter(key) {
        let value = key.value
        var modifiers = activeCommandModifiers()
        if (key.type === "letter") {
            const commandModifierHeld = modifiers.length > 0
            const upperCase = commandModifierHeld ? shifted : shifted !== capsLocked
            if (upperCase) modifiers = modifiers.concat(["Shift"])
            value = key.value.toLowerCase()
        } else if (shifted && key.shiftedValue) {
            modifiers = modifiers.concat(["Shift"])
        }

        if (modifiers.length > 0) inputBackend.sendChord(modifiers, value)
        else inputBackend.sendText(value)
        clearOneShotShift()
    }

    function activeCommandModifiers() {
        if (controlHeld && altHeld && metaHeld) return ["Ctrl", "Alt", "Meta"]
        if (controlHeld && altHeld) return ["Ctrl", "Alt"]
        if (controlHeld && metaHeld) return ["Ctrl", "Meta"]
        if (altHeld && metaHeld) return ["Alt", "Meta"]
        if (controlHeld) return ["Ctrl"]
        if (altHeld) return ["Alt"]
        if (metaHeld) return ["Meta"]
        return []
    }

    function sendSpecialKey(key) {
        var modifiers = activeCommandModifiers()
        if (shifted) modifiers = modifiers.concat(["Shift"])
        if (modifiers.length > 0) inputBackend.sendChord(modifiers, key.value)
        else inputBackend.sendKey(key.value)
        clearOneShotShift()
    }

    function activate(key) {
        if (key.value === "Shift" && shiftLongPressConsumed) {
            shiftLongPressConsumed = false
            return
        }
        if (key.type === "modifier") {
            toggleModifier(key.value)
        } else if (key.type === "lock") {
            capsLocked = !capsLocked
        } else if (key.type === "key") {
            sendSpecialKey(key)
        } else {
            sendCharacter(key)
        }
    }

    ColumnLayout {
        anchors.fill: parent
        spacing: 4

        Repeater {
            model: root.rows
            RowLayout {
                required property var modelData
                Layout.fillWidth: true
                Layout.fillHeight: true
                spacing: 4

                Repeater {
                    model: parent.modelData
                    KeyCap {
                        required property var modelData
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        Layout.preferredWidth: modelData.width || 46
                        showBorders: root.appearanceStore.keyBordersVisible
                        keyLabel: modelData.type === "letter"
                                  && (root.shifted !== root.capsLocked)
                                  ? modelData.label.toUpperCase()
                                  : root.shifted && modelData.shiftedLabel
                                    ? modelData.shiftedLabel : modelData.label
                        subLabel: modelData.value === "Shift" && root.shiftLocked
                                  ? "LOCK" : ""
                        repeatEnabled: modelData.type === "key"
                                       && root.repeatableKey(modelData.value)
                                       && !root.repeatBlockingModifierActive()
                        toolTipText: modelData.shiftedLabel && !root.shifted
                                     ? "Shift: " + modelData.shiftedLabel : ""
                        accent: modelData.type === "lock" && root.capsLocked
                                ? "#72ff9f"
                                : modelData.value === "Shift" && root.shiftLocked
                                  ? "#ffcf5a"
                                  : modelData.type === "modifier" && root.modifierActive(modelData.value)
                                  ? "#72ff9f" : root.appearanceStore.primary
                        onPressAndHold: root.holdModifier(modelData.value)
                        onClicked: root.activate(modelData)
                    }
                }
            }
        }
    }
}
