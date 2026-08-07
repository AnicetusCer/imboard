// SPDX-FileCopyrightText: 2026 AnicetusCer
// SPDX-License-Identifier: GPL-3.0-or-later

import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Popup {
    id: root

    required property var appearanceStore
    required property var inputController

    objectName: "inputDiagnosticsPopup"
    x: Math.round((parent.width - width) / 2)
    y: Math.round((parent.height - height) / 2)
    width: Math.min(610, parent.width - 30)
    height: Math.min(285, parent.height - 20)
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
        objectName: "inputDiagnosticsContent"
        spacing: 6

        Label {
            Layout.fillWidth: true
            text: "INPUT DIAGNOSTICS"
            color: root.appearanceStore.primary
            font.bold: true
            font.pixelSize: 12
            style: Text.Outline
            styleColor: "#f0000000"
        }

        Label {
            Layout.fillWidth: true
            text: "Counts stay in memory and reset when Imboard exits. No key names or typed text are recorded. Close this panel, type normally, then return here to review the results."
            color: root.appearanceStore.secondary
            font.pixelSize: 9
            wrapMode: Text.WordWrap
        }

        GridLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            columns: 2
            columnSpacing: 12
            rowSpacing: 4

            Label {
                text: "TOUCHES"
                color: root.appearanceStore.primary
                font.bold: true
                font.pixelSize: 10
            }
            Label {
                Layout.fillWidth: true
                text: "START " + root.inputController.diagnosticTouchStarts
                      + "   ACTIVATED " + root.inputController.diagnosticTouchActivations
                      + "   CANCELLED " + root.inputController.diagnosticTouchCancellations
                color: root.appearanceStore.secondary
                font.pixelSize: 10
            }

            Label {
                text: "ACTIONS"
                color: root.appearanceStore.primary
                font.bold: true
                font.pixelSize: 10
            }
            Label {
                Layout.fillWidth: true
                text: "REQUESTED " + root.inputController.diagnosticActionsRequested
                      + "   COMPLETED " + root.inputController.diagnosticActionsCompleted
                      + "   FAILED " + root.inputController.diagnosticActionsFailed
                color: root.inputController.diagnosticActionsFailed > 0
                       ? "#ff6d91" : root.appearanceStore.secondary
                font.pixelSize: 10
            }

            Label {
                text: "PORTAL EVENTS"
                color: root.appearanceStore.primary
                font.bold: true
                font.pixelSize: 10
            }
            Label {
                Layout.fillWidth: true
                text: "ACCEPTED " + root.inputController.diagnosticPortalEventsAccepted
                      + "   FAILED " + root.inputController.diagnosticPortalEventsFailed
                color: root.inputController.diagnosticPortalEventsFailed > 0
                       ? "#ff6d91" : root.appearanceStore.secondary
                font.pixelSize: 10
            }

            Label {
                text: "PORTAL LATENCY"
                color: root.appearanceStore.primary
                font.bold: true
                font.pixelSize: 10
            }
            Label {
                Layout.fillWidth: true
                text: "LAST " + root.inputController.diagnosticLastPortalLatencyMs
                      + " ms   AVERAGE "
                      + root.inputController.diagnosticAveragePortalLatencyMs.toFixed(1)
                      + " ms   WORST " + root.inputController.diagnosticWorstPortalLatencyMs
                      + " ms"
                color: root.inputController.diagnosticWorstPortalLatencyMs >= 100
                       ? "#ffb43b" : root.appearanceStore.secondary
                font.pixelSize: 10
            }
        }

        RowLayout {
            Layout.fillWidth: true
            Layout.preferredHeight: 34

            KeyCap {
                Layout.preferredWidth: 88
                Layout.fillHeight: true
                compact: true
                showBorders: root.appearanceStore.keyBordersVisible
                keyLabel: "RESET"
                accent: root.appearanceStore.primary
                toolTipText: "Clear all in-memory diagnostic counters"
                onClicked: root.inputController.resetInputDiagnostics()
            }
            Item { Layout.fillWidth: true }
            KeyCap {
                Layout.preferredWidth: 88
                Layout.fillHeight: true
                compact: true
                showBorders: root.appearanceStore.keyBordersVisible
                keyLabel: "STOP"
                accent: "#ff6d91"
                toolTipText: "Stop input diagnostics; current counters remain until reset or exit"
                onClicked: {
                    root.inputController.inputDiagnosticsEnabled = false
                    root.close()
                }
            }
            KeyCap {
                Layout.preferredWidth: 88
                Layout.fillHeight: true
                compact: true
                showBorders: root.appearanceStore.keyBordersVisible
                keyLabel: "CLOSE"
                accent: root.appearanceStore.secondary
                toolTipText: "Close this panel and continue collecting diagnostics"
                onClicked: root.close()
            }
        }
    }
}
