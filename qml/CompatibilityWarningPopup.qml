// SPDX-FileCopyrightText: 2026 AnicetusCer
// SPDX-License-Identifier: GPL-3.0-or-later

import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Popup {
    id: root

    required property var appearanceStore
    required property var compatibilityStore

    objectName: "compatibilityWarningPopup"
    x: Math.round((parent.width - width) / 2)
    y: Math.round((parent.height - height) / 2)
    width: Math.min(620, parent.width - 40)
    height: Math.min(220, parent.height - 30)
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
            text: "KDE WAYLAND RECOMMENDED"
            color: root.appearanceStore.primary
            font.bold: true
            font.pixelSize: 13
            style: Text.Outline
            styleColor: "#f0000000"
        }

        Label {
            Layout.fillWidth: true
            Layout.fillHeight: true
            text: "IMBOARD is designed and tested for KDE Wayland, including SteamOS Desktop Mode.\n\n"
                  + "This session does not appear to be KDE, so some features may not work correctly."
            color: "#eaffff"
            font.pixelSize: 11
            wrapMode: Text.WordWrap
            verticalAlignment: Text.AlignVCenter
        }

        RowLayout {
            Layout.fillWidth: true
            Layout.preferredHeight: 38

            Item {
                Layout.fillWidth: true
            }

            KeyCap {
                Layout.preferredWidth: 110
                Layout.fillHeight: true
                showBorders: root.appearanceStore.keyBordersVisible
                keyLabel: "OK"
                accent: root.appearanceStore.secondary
                toolTipText: "Do not show this compatibility note again"
                onClicked: {
                    root.compatibilityStore.dismissNonKdeWarning()
                    root.close()
                }
            }
        }
    }
}
