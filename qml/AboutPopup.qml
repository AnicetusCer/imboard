// SPDX-FileCopyrightText: 2026 AnicetusCer
// SPDX-License-Identifier: GPL-3.0-or-later

import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Popup {
    id: root

    required property var appearanceStore

    objectName: "aboutPopup"
    x: Math.round((parent.width - width) / 2)
    y: Math.round((parent.height - height) / 2)
    width: Math.min(620, parent.width - 40)
    height: Math.min(360, parent.height - 16)
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
        spacing: 9

        RowLayout {
            Layout.fillWidth: true
            Layout.preferredHeight: 28
            Label {
                Layout.fillWidth: true
                text: "ABOUT IMBOARD"
                color: root.appearanceStore.primary
                font.bold: true
                font.pixelSize: 11
                style: Text.Outline
                styleColor: "#f0000000"
            }
            KeyCap {
                Layout.preferredWidth: 54
                Layout.preferredHeight: 24
                Layout.alignment: Qt.AlignVCenter
                compact: true
                showBorders: root.appearanceStore.keyBordersVisible
                keyLabel: "CLOSE"
                accent: root.appearanceStore.secondary
                toolTipText: "Close About"
                onClicked: root.close()
            }
        }

        ScrollView {
            id: aboutTextScroll
            Layout.fillWidth: true
            Layout.fillHeight: true
            clip: true
            contentWidth: availableWidth
            ScrollBar.horizontal.policy: ScrollBar.AlwaysOff

            Label {
                width: aboutTextScroll.availableWidth
                text: "IMBOARD is a handy virtual keyboard built mainly for the Steam Deck. It is designed to make developer keys and shortcuts easier to reach without plugging in a physical keyboard.\n\nIt gives quick access to common keys that are awkward or missing on the built-in SteamOS virtual keyboard. SteamOS is its first home, but IMBOARD is designed to work across other Wayland-based KDE Linux desktops too.\n\nThis is a one-person project by me, AnicetusCer. Feedback is welcome through the GitHub support page, or through Ko-fi if you leave a tip and message there, but please do not expect instant replies.\n\nIf IMBOARD has helped you, consider leaving a tip through the Ko-fi link below. More than anything, it lets me know people are using it out there in the wild, which can be hard to tell while the app is private."
                color: "#eaffff"
                font.pixelSize: 11
                wrapMode: Text.WordWrap
            }
        }

        GridLayout {
            Layout.fillWidth: true
            Layout.minimumHeight: 58
            Layout.preferredHeight: 62
            Layout.maximumHeight: 66
            columns: 3
            columnSpacing: 8
            rowSpacing: 8

            KeyCap {
                Layout.fillWidth: true
                Layout.preferredHeight: 58
                showBorders: root.appearanceStore.keyBordersVisible
                keyLabel: "GITHUB"
                accent: root.appearanceStore.primary
                toolTipText: "Open the Imboard support page"
                onClicked: Qt.openUrlExternally("https://github.com/AnicetusCer/imboard/blob/main/SUPPORT.md")
            }
            KeyCap {
                Layout.fillWidth: true
                Layout.preferredHeight: 58
                showBorders: root.appearanceStore.keyBordersVisible
                keyLabel: "KO-FI"
                accent: "#ffb43b"
                toolTipText: "Open Ko-fi support page"
                onClicked: Qt.openUrlExternally("https://ko-fi.com/anicetuscer")
            }
            KeyCap {
                Layout.fillWidth: true
                Layout.preferredHeight: 58
                showBorders: root.appearanceStore.keyBordersVisible
                keyLabel: "PRIVACY"
                accent: root.appearanceStore.secondary
                toolTipText: "Open Imboard privacy notes"
                onClicked: Qt.openUrlExternally("https://github.com/AnicetusCer/imboard/blob/main/PRIVACY.md")
            }
        }

        Label {
            Layout.fillWidth: true
            text: "GPL-3.0-or-later. Emoji artwork is Twemoji under CC BY 4.0."
            color: Qt.alpha("#eaffff", 0.78)
            font.pixelSize: 9
            elide: Text.ElideRight
        }
    }
}
