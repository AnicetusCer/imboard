// SPDX-FileCopyrightText: 2026 AnicetusCer
// SPDX-License-Identifier: GPL-3.0-or-later

import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Rectangle {
    id: root

    required property var appearanceStore
    required property var inputController
    required property var speechController

    readonly property bool transcriptCanApply:
        inputController.canSendText(transcriptArea.text)
    property bool active: false
    property string deliveryError: ""

    function beginTranscription() {
        deliveryError = ""
        transcriptArea.text = ""
        speechController.clearTranscript()
        inputController.localTextEditing = true
        active = true
        speechController.startRecording()
    }

    function cancelTranscription() {
        inputController.localTextEditing = false
        speechController.cancel()
        active = false
    }

    function recordAgain() {
        deliveryError = ""
        transcriptArea.text = ""
        speechController.clearTranscript()
        speechController.startRecording()
    }

    function applyTranscription() {
        const editedText = transcriptArea.text
        if (!inputController.canSendText(editedText)) return
        inputController.localTextEditing = false
        if (inputController.sendText(editedText)) {
            deliveryError = ""
            speechController.cancel()
            active = false
        } else {
            inputController.localTextEditing = true
            deliveryError =
                "Keyboard input was interrupted. The transcript was kept; check the target before retrying."
        }
    }

    function replaceSelection(value) {
        if (speechController.phase !== "ready") return
        const start = Math.min(transcriptArea.selectionStart, transcriptArea.selectionEnd)
        const end = Math.max(transcriptArea.selectionStart, transcriptArea.selectionEnd)
        if (end > start) transcriptArea.remove(start, end)
        transcriptArea.insert(start, value)
        transcriptArea.cursorPosition = start + value.length
    }

    function removeSelection() {
        const start = Math.min(transcriptArea.selectionStart, transcriptArea.selectionEnd)
        const end = Math.max(transcriptArea.selectionStart, transcriptArea.selectionEnd)
        if (end <= start) return false
        transcriptArea.remove(start, end)
        transcriptArea.cursorPosition = start
        return true
    }

    function keepCursorVisible() {
        if (!active) return
        Qt.callLater(function() {
            const cursor = transcriptArea.cursorRectangle
            if (cursor.y < transcriptViewport.contentY) {
                transcriptViewport.contentY = Math.max(0, cursor.y - 3)
            } else if (cursor.y + cursor.height
                       > transcriptViewport.contentY + transcriptViewport.height) {
                transcriptViewport.contentY = Math.min(
                    Math.max(0, transcriptViewport.contentHeight - transcriptViewport.height),
                    cursor.y + cursor.height - transcriptViewport.height + 3)
            }
        })
    }

    function handleLocalKey(key) {
        if (!active || speechController.phase !== "ready") return
        if (key === "Backspace") {
            if (!removeSelection() && transcriptArea.cursorPosition > 0) {
                const position = transcriptArea.cursorPosition
                let start = position - 1
                const trailing = transcriptArea.text.charCodeAt(start)
                if (start > 0 && trailing >= 0xdc00 && trailing <= 0xdfff) {
                    const leading = transcriptArea.text.charCodeAt(start - 1)
                    if (leading >= 0xd800 && leading <= 0xdbff) --start
                }
                transcriptArea.remove(start, position)
                transcriptArea.cursorPosition = start
            }
        } else if (key === "Delete") {
            if (!removeSelection()
                    && transcriptArea.cursorPosition < transcriptArea.length) {
                const position = transcriptArea.cursorPosition
                let end = position + 1
                const leading = transcriptArea.text.charCodeAt(position)
                if (end < transcriptArea.length
                        && leading >= 0xd800 && leading <= 0xdbff) {
                    const trailing = transcriptArea.text.charCodeAt(end)
                    if (trailing >= 0xdc00 && trailing <= 0xdfff) ++end
                }
                transcriptArea.remove(position, end)
            }
        } else if (key === "Left") {
            transcriptArea.cursorPosition = Math.max(0, transcriptArea.cursorPosition - 1)
        } else if (key === "Right") {
            transcriptArea.cursorPosition = Math.min(transcriptArea.length,
                                                     transcriptArea.cursorPosition + 1)
        } else if (key === "Up" || key === "Down") {
            const cursor = transcriptArea.cursorRectangle
            const lineStep = Math.max(cursor.height, transcriptArea.font.pixelSize + 2)
            const targetY = key === "Up" ? Math.max(0, cursor.y - lineStep)
                                          : cursor.y + lineStep
            transcriptArea.cursorPosition = transcriptArea.positionAt(cursor.x, targetY)
        } else if (key === "Home") {
            transcriptArea.cursorPosition = 0
        } else if (key === "End") {
            transcriptArea.cursorPosition = transcriptArea.length
        } else if (key === "Space") {
            replaceSelection(" ")
        } else if (key === "Enter") {
            replaceSelection("\n")
        } else if (key === "Tab") {
            replaceSelection("\t")
        }
    }

    function handleLocalChord(modifiers, key) {
        if (!active || speechController.phase !== "ready") return
        const lowerKey = key.toLowerCase()
        if (modifiers.length === 1 && modifiers[0] === "Ctrl" && lowerKey === "a")
            transcriptArea.selectAll()
        else if (modifiers.length === 1 && modifiers[0] === "Ctrl" && lowerKey === "z")
            transcriptArea.undo()
        else if (modifiers.indexOf("Ctrl") >= 0
                 && modifiers.indexOf("Shift") >= 0 && lowerKey === "z")
            transcriptArea.redo()
        else if (modifiers.length === 1 && modifiers[0] === "Ctrl" && lowerKey === "y")
            transcriptArea.redo()
    }

    objectName: "transcriptionStrip"
    height: 104
    radius: 8
    color: Qt.alpha("#07101f", 0.94)
    border.width: root.appearanceStore.frameBordersVisible ? 2 : 0
    border.color: root.appearanceStore.primary

    Connections {
        target: root.speechController
        function onTranscriptChanged() {
            transcriptArea.text = root.speechController.transcript
            if (root.speechController.phase === "ready")
                transcriptArea.cursorPosition = transcriptArea.length
        }
    }

    Connections {
        target: root.inputController
        function onLocalTextRequested(text) {
            root.replaceSelection(text)
        }
        function onLocalKeyRequested(key) {
            root.handleLocalKey(key)
        }
        function onLocalChordRequested(modifiers, key) {
            root.handleLocalChord(modifiers, key)
        }
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 5
        spacing: 4

        RowLayout {
            Layout.fillWidth: true
            Layout.minimumHeight: 30
            Layout.preferredHeight: 30
            Layout.maximumHeight: 30
            spacing: 5

            Label {
                text: "TRANSCRIPTION"
                color: root.appearanceStore.primary
                font.bold: true
                font.pixelSize: 10
            }

            Label {
                Layout.fillWidth: true
                text: root.deliveryError.length > 0
                      ? root.deliveryError
                      : root.speechController.phase === "ready"
                      && transcriptArea.text.length > 0
                      && !root.transcriptCanApply
                      ? "Non-ASCII text needs Experimental Unicode in CONFIG."
                      : root.speechController.status
                color: root.deliveryError.length > 0
                       || root.speechController.phase === "error"
                       ? "#ff8aa5" : "#eaffff"
                font.pixelSize: 9
                elide: Text.ElideRight
            }

            Label {
                Layout.preferredWidth: 60
                horizontalAlignment: Text.AlignHCenter
                text: root.speechController.recording
                      ? root.speechController.recordingSecondsRemaining + "s"
                      : root.speechController.transcribing ? "WORKING" : "READY"
                color: root.speechController.recording ? "#ff6d91"
                                                       : root.appearanceStore.secondary
                font.bold: true
                font.pixelSize: 9
            }

            KeyCap {
                Layout.preferredWidth: 68
                Layout.fillHeight: true
                keyLabel: "CANCEL"
                accent: "#ff6d91"
                showBorders: root.appearanceStore.keyBordersVisible
                onClicked: root.cancelTranscription()
            }

            KeyCap {
                visible: root.speechController.recording
                Layout.preferredWidth: 126
                Layout.fillHeight: true
                keyLabel: "STOP & TRANSCRIBE"
                accent: root.appearanceStore.secondary
                showBorders: root.appearanceStore.keyBordersVisible
                onClicked: root.speechController.stopAndTranscribe()
            }

            KeyCap {
                visible: !root.speechController.recording
                         && !root.speechController.transcribing
                Layout.preferredWidth: 92
                Layout.fillHeight: true
                keyLabel: "AGAIN"
                accent: root.appearanceStore.secondary
                showBorders: root.appearanceStore.keyBordersVisible
                onClicked: root.recordAgain()
            }

            KeyCap {
                Layout.preferredWidth: 68
                Layout.fillHeight: true
                enabled: !root.speechController.recording
                         && !root.speechController.transcribing
                         && transcriptArea.text.trim().length > 0
                         && root.transcriptCanApply
                         && root.inputController.backendReady
                opacity: enabled ? 1.0 : 0.45
                keyLabel: "APPLY"
                accent: "#72ff9f"
                showBorders: root.appearanceStore.keyBordersVisible
                onClicked: root.applyTranscription()
            }
        }

        Flickable {
            id: transcriptViewport
            objectName: "transcriptViewport"
            Layout.fillWidth: true
            Layout.fillHeight: true
            clip: true
            contentWidth: width
            contentHeight: Math.max(height, transcriptArea.height + 4)
            boundsBehavior: Flickable.StopAtBounds
            flickableDirection: Flickable.VerticalFlick

            ScrollBar.vertical: ScrollBar {
                policy: transcriptViewport.contentHeight > transcriptViewport.height
                        ? ScrollBar.AsNeeded : ScrollBar.AlwaysOff
            }

            TextArea {
                id: transcriptArea
                objectName: "transcriptArea"
                x: 0
                y: 0
                width: Math.max(1, transcriptViewport.width - 14)
                height: Math.max(transcriptViewport.height, implicitHeight + 2)
                enabled: root.speechController.phase === "ready"
                placeholderText: root.speechController.recording
                                 ? "Speak, then choose STOP & TRANSCRIBE…"
                                 : root.speechController.transcribing
                                   ? "Processing privately on this device…"
                                   : "Use the keyboard below to correct this text."
                color: "#f2ffff"
                placeholderTextColor: "#88d9e6"
                selectionColor: Qt.alpha(root.appearanceStore.primary, 0.45)
                selectedTextColor: "white"
                font.pixelSize: 12
                wrapMode: TextEdit.Wrap
                persistentSelection: true
                padding: 5
                onCursorPositionChanged: root.keepCursorVisible()
                background: Rectangle {
                    radius: 5
                    color: "#d90d1728"
                    border.width: 1
                    border.color: root.appearanceStore.secondary
                }
            }
        }
    }
}
