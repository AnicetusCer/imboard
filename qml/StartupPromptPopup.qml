// SPDX-FileCopyrightText: 2026 AnicetusCer
// SPDX-License-Identifier: GPL-3.0-or-later

import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Popup {
    id: root

    required property var appearanceStore
    required property var startupManager

    objectName: "startupPromptPopup"
    x: Math.round((parent.width - width) / 2)
    y: Math.round((parent.height - height) / 2)
    width: Math.min(650, parent.width - 40)
    height: Math.min(260, parent.height - 30)
    padding: 14
    modal: true
    dim: false
    closePolicy: Popup.NoAutoClose

    background: Rectangle {
        radius: 12
        color: "#fa0a1020"
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
        spacing: 10

        Label {
            Layout.fillWidth: true
            text: "KEEP IMBOARD AVAILABLE?"
            color: root.appearanceStore.primary
            font.bold: true
            font.pixelSize: 13
            style: Text.Outline
            styleColor: "#f0000000"
        }

        Label {
            Layout.fillWidth: true
            Layout.fillHeight: true
            text: "Imboard can start automatically when you log in and stay hidden in the system tray. "
                  + "Use the tray icon whenever you want to show or hide the keyboard.\n\n"
                  + "If you choose NO, Imboard will not run automatically. You can still open it later from Utilities."
            color: "#eaffff"
            font.pixelSize: 11
            wrapMode: Text.WordWrap
            verticalAlignment: Text.AlignVCenter
        }

        RowLayout {
            Layout.fillWidth: true
            Layout.preferredHeight: 36

            Label {
                Layout.fillWidth: true
                text: root.startupManager.error
                color: "#ff6d91"
                font.pixelSize: 10
                elide: Text.ElideRight
            }

            KeyCap {
                Layout.preferredWidth: 100
                Layout.fillHeight: true
                showBorders: root.appearanceStore.keyBordersVisible
                keyLabel: "NO"
                accent: root.appearanceStore.primary
                toolTipText: "Do not start Imboard automatically; open it manually from Utilities"
                onClicked: {
                    root.startupManager.declineStartupPrompt()
                    root.close()
                }
            }

            KeyCap {
                Layout.preferredWidth: 150
                Layout.fillHeight: true
                showBorders: root.appearanceStore.keyBordersVisible
                keyLabel: root.startupManager.busy ? "WAIT" : "YES"
                accent: "#72ff9f"
                toolTipText: "Start Imboard at login, hidden in the system tray"
                onClicked: {
                    if (!root.startupManager.busy)
                        root.startupManager.acceptStartupPrompt()
                    if (!root.startupManager.busy)
                        root.close()
                }
            }
        }
    }
}
