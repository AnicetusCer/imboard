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

    function toggleModifier(value) {
        if (value === "Shift") shifted = !shifted
        else if (value === "Ctrl") controlHeld = !controlHeld
        else if (value === "Alt") altHeld = !altHeld
        else if (value === "Meta") metaHeld = !metaHeld
    }

    function sendCharacter(key) {
        let value = key.value
        if (key.type === "letter") {
            const upperCase = shifted !== capsLocked
            value = upperCase ? key.value.toUpperCase() : key.value
        } else if (shifted && key.shiftedValue) {
            value = key.shiftedValue
        }

        const modifiers = []
        if (controlHeld) modifiers.push("Ctrl")
        if (altHeld) modifiers.push("Alt")
        if (metaHeld) modifiers.push("Meta")
        if (modifiers.length > 0) inputBackend.sendChord(modifiers, value)
        else inputBackend.sendText(value)
        shifted = false
    }

    function activate(key) {
        if (key.type === "modifier") {
            toggleModifier(key.value)
        } else if (key.type === "lock") {
            capsLocked = !capsLocked
            inputBackend.sendKey(key.value)
        } else if (key.type === "key") {
            inputBackend.sendKey(key.value)
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
                        repeatEnabled: modelData.type === "key"
                                       && modelData.value === "Backspace"
                        toolTipText: modelData.shiftedLabel && !root.shifted
                                     ? "Shift: " + modelData.shiftedLabel : ""
                        accent: modelData.type === "lock" && root.capsLocked
                                ? "#72ff9f"
                                : modelData.type === "modifier" && root.modifierActive(modelData.value)
                                  ? "#72ff9f" : root.appearanceStore.primary
                        onClicked: root.activate(modelData)
                    }
                }
            }
        }
    }
}
