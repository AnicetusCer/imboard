// SPDX-FileCopyrightText: 2026 AnicetusCer
// SPDX-License-Identifier: GPL-3.0-or-later

import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Popup {
    id: root

    required property var appearanceStore
    required property var inputController

    objectName: "removeAccessPopup"
    x: Math.round((parent.width - width) / 2)
    y: Math.round((parent.height - height) / 2)
    width: Math.min(560, parent.width - 40)
    height: Math.min(220, parent.height - 20)
    padding: 14
    modal: true
    dim: false
    closePolicy: Popup.NoAutoClose

    background: Rectangle {
        radius: 12
        color: "#fa0a1020"
        border.width: 4
        border.color: "#ff6d91"
    }

    contentItem: ColumnLayout {
        spacing: 9
        Label {
            Layout.fillWidth: true
            text: "REMOVE KEYBOARD ACCESS?"
            color: "#ff6d91"
            font.bold: true
            font.pixelSize: 13
        }
        Label {
            Layout.fillWidth: true
            Layout.fillHeight: true
            text: "Imboard will disconnect immediately, delete its saved restore token, and forget that keyboard access was set up.\n\n"
                  + "Your system may still keep a saved XDG portal permission entry for Imboard. You can clear that later from your system privacy settings or by resetting Imboard's portal permissions."
                  + (root.inputController.backendStatus.indexOf("Could not") === 0
                     ? "\n\nERROR: " + root.inputController.backendStatus : "")
            color: "#eaffff"
            font.pixelSize: 11
            wrapMode: Text.WordWrap
            verticalAlignment: Text.AlignVCenter
        }
        RowLayout {
            Layout.fillWidth: true
            Layout.preferredHeight: 34
            Item { Layout.fillWidth: true }
            KeyCap {
                Layout.preferredWidth: 90
                Layout.fillHeight: true
                showBorders: root.appearanceStore.keyBordersVisible
                keyLabel: "CANCEL"
                accent: root.appearanceStore.primary
                toolTipText: "Keep keyboard access"
                onClicked: root.close()
            }
            KeyCap {
                Layout.preferredWidth: 145
                Layout.fillHeight: true
                showBorders: root.appearanceStore.keyBordersVisible
                keyLabel: "REMOVE ACCESS"
                accent: "#ff6d91"
                toolTipText: "Disconnect and permanently forget Imboard's saved permission token"
                onClicked: {
                    if (root.inputController.forgetPortalPermission())
                        root.close()
                }
            }
        }
    }
}
