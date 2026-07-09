// SPDX-FileCopyrightText: 2026 AnicetusCer
// SPDX-License-Identifier: GPL-3.0-or-later

import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Popup {
    id: root

    required property var appearanceStore
    required property var inputController
    required property var startupManager
    required property bool portalBusy

    signal permissionSetupRequested
    signal removeAccessRequested

    function customPadColumnLabel() {
        if (root.appearanceStore.customPadColumns === 0) return "AUTO"
        return root.appearanceStore.customPadColumns + " COL"
    }

    function cycleCustomPadColumns() {
        const next = root.appearanceStore.customPadColumns >= 4
                     ? 0 : root.appearanceStore.customPadColumns + 1
        root.appearanceStore.setCustomPadColumns(next)
    }

    objectName: "configPopup"
    x: Math.round((parent.width - width) / 2)
    y: Math.round((parent.height - height) / 2)
    width: Math.min(520, parent.width - 40)
    height: Math.min(315, parent.height - 30)
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
        spacing: 7

        RowLayout {
            Layout.fillWidth: true
            Layout.preferredHeight: 25
            Label {
                Layout.fillWidth: true
                text: "IMBOARD CONFIGURATION"
                color: root.appearanceStore.primary
                font.bold: true
                font.pixelSize: 11
                style: Text.Outline
                styleColor: "#f0000000"
            }
            KeyCap {
                Layout.preferredWidth: 54
                Layout.fillHeight: true
                compact: true
                showBorders: root.appearanceStore.keyBordersVisible
                keyLabel: "CLOSE"
                accent: root.appearanceStore.secondary
                toolTipText: "Close configuration without changing other settings"
                onClicked: root.close()
            }
        }

        RowLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            Label {
                Layout.fillWidth: true
                text: root.startupManager.error.length > 0
                      ? root.startupManager.error : "RUN AT LOGIN"
                color: root.startupManager.error.length > 0
                       ? "#ff6d91" : root.appearanceStore.secondary
                font.bold: true
                font.pixelSize: 10
                elide: Text.ElideRight
            }
            KeyCap {
                Layout.preferredWidth: 76
                Layout.fillHeight: true
                showBorders: root.appearanceStore.keyBordersVisible
                keyLabel: root.startupManager.busy ? "WAIT"
                          : root.startupManager.enabled ? "ON" : "OFF"
                accent: root.startupManager.enabled
                        ? "#72ff9f" : root.appearanceStore.primary
                toolTipText: "Start Imboard automatically after login, hidden in the system tray"
                onClicked: {
                    if (!root.startupManager.busy)
                        root.startupManager.setEnabled(!root.startupManager.enabled)
                }
            }
        }

        RowLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            Label {
                Layout.fillWidth: true
                text: root.inputController.backendReady
                      ? "KEYBOARD INPUT"
                      : root.inputController.backendStatus.toUpperCase()
                color: root.inputController.backendReady
                       ? root.appearanceStore.secondary : "#ffb43b"
                font.bold: true
                font.pixelSize: 10
                elide: Text.ElideRight
            }
            KeyCap {
                Layout.preferredWidth: 76
                Layout.fillHeight: true
                showBorders: root.appearanceStore.keyBordersVisible
                keyLabel: root.inputController.backendReady ? "REMOVE"
                          : root.portalBusy ? "WAIT" : "REPAIR"
                accent: root.inputController.backendReady ? "#ff6d91" : "#ffb43b"
                toolTipText: root.inputController.backendReady
                             ? "Disconnect Imboard and forget its saved keyboard-access permission"
                             : "Keyboard input is unavailable; reopen the required setup explanation"
                onClicked: {
                    if (root.inputController.backendReady)
                        root.removeAccessRequested()
                    else if (!root.portalBusy)
                        root.permissionSetupRequested()
                }
            }
        }

        RowLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            Label {
                Layout.fillWidth: true
                text: "EXPERIMENTAL EMOJI / UNICODE"
                color: root.inputController.experimentalUnicodeEnabled
                       ? root.appearanceStore.secondary : root.appearanceStore.primary
                font.bold: true
                font.pixelSize: 10
                elide: Text.ElideRight
            }
            KeyCap {
                Layout.preferredWidth: 76
                Layout.fillHeight: true
                showBorders: root.appearanceStore.keyBordersVisible
                keyLabel: root.inputController.experimentalUnicodeEnabled ? "ON" : "OFF"
                accent: root.inputController.experimentalUnicodeEnabled
                        ? "#72ff9f" : root.appearanceStore.primary
                toolTipText: "Experimental: allows emoji and other non-ASCII text by temporarily using the clipboard and pasting with Ctrl+V"
                onClicked: root.inputController.experimentalUnicodeEnabled =
                           !root.inputController.experimentalUnicodeEnabled
            }
        }

        RowLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            Label {
                Layout.fillWidth: true
                text: "CUSTOM PAD ONLY MODE"
                color: root.appearanceStore.customPadOnlyEnabled
                       ? root.appearanceStore.secondary : root.appearanceStore.primary
                font.bold: true
                font.pixelSize: 10
                elide: Text.ElideRight
            }
            KeyCap {
                Layout.preferredWidth: 76
                Layout.fillHeight: true
                showBorders: root.appearanceStore.keyBordersVisible
                keyLabel: root.appearanceStore.customPadOnlyEnabled ? "ON" : "OFF"
                accent: root.appearanceStore.customPadOnlyEnabled
                        ? "#72ff9f" : root.appearanceStore.primary
                toolTipText: "Switch the window to a compact pad showing only custom keys"
                onClicked: {
                    root.appearanceStore.setCustomPadOnlyEnabled(
                        !root.appearanceStore.customPadOnlyEnabled)
                    root.close()
                }
            }
        }

        RowLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            Label {
                Layout.fillWidth: true
                text: "CUSTOM PAD ONLY MODE KEYS"
                color: root.appearanceStore.secondary
                font.bold: true
                font.pixelSize: 10
                elide: Text.ElideRight
            }
            KeyCap {
                Layout.preferredWidth: 44
                Layout.fillHeight: true
                showBorders: root.appearanceStore.keyBordersVisible
                keyLabel: "-"
                accent: root.appearanceStore.primary
                toolTipText: "Show fewer custom keys in compact mode"
                onClicked: root.appearanceStore.setCustomPadKeyCount(
                           root.appearanceStore.customPadKeyCount - 1)
            }
            Label {
                Layout.preferredWidth: 38
                horizontalAlignment: Text.AlignHCenter
                text: root.appearanceStore.customPadKeyCount
                color: root.appearanceStore.secondary
                font.bold: true
                font.pixelSize: 12
                style: Text.Outline
                styleColor: "#f0000000"
            }
            KeyCap {
                Layout.preferredWidth: 44
                Layout.fillHeight: true
                showBorders: root.appearanceStore.keyBordersVisible
                keyLabel: "+"
                accent: root.appearanceStore.primary
                toolTipText: "Show more custom keys in compact mode"
                onClicked: root.appearanceStore.setCustomPadKeyCount(
                           root.appearanceStore.customPadKeyCount + 1)
            }
        }

        RowLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            Label {
                Layout.fillWidth: true
                text: "CUSTOM PAD ONLY MODE GRID"
                color: root.appearanceStore.secondary
                font.bold: true
                font.pixelSize: 10
                elide: Text.ElideRight
            }
            KeyCap {
                Layout.preferredWidth: 76
                Layout.fillHeight: true
                showBorders: root.appearanceStore.keyBordersVisible
                keyLabel: root.customPadColumnLabel()
                accent: root.appearanceStore.primary
                toolTipText: "Cycle compact custom pad columns: auto, 1, 2, 3, or 4"
                onClicked: root.cycleCustomPadColumns()
            }
        }
    }
}
