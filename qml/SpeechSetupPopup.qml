// SPDX-FileCopyrightText: 2026 AnicetusCer
// SPDX-License-Identifier: GPL-3.0-or-later

import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Popup {
    id: root

    required property var appearanceStore
    readonly property string releasesUrl:
        "https://github.com/AnicetusCer/imboard/releases/latest"
    property bool releaseOpenFailed: false

    objectName: "speechSetupPopup"
    x: Math.round((parent.width - width) / 2)
    y: Math.round((parent.height - height) / 2)
    width: Math.min(620, parent.width - 40)
    height: Math.min(245, parent.height - 30)
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
        spacing: 8

        Label {
            Layout.fillWidth: true
            text: "OFFLINE TRANSCRIPTION ADD-ON"
            color: root.appearanceStore.primary
            font.bold: true
            font.pixelSize: 11
            style: Text.Outline
            styleColor: "#f0000000"
        }

        Label {
            Layout.fillWidth: true
            text: "IMBOARD supports private, on-device transcription when the optional Whisper small.en add-on is installed."
            color: root.appearanceStore.secondary
            wrapMode: Text.WordWrap
            font.pixelSize: 10
        }

        Label {
            Layout.fillWidth: true
            text: "To enable transcription, download imboard-model-small-en-*.flatpak from the IMBOARD GitHub release. Open it with Discover or install it with Flatpak, then restart IMBOARD. The add-on is about 410 MB. Once installed, transcription runs entirely on your device and does not require internet access."
                  + (root.releaseOpenFailed
                     ? "\n\nCould not open your browser. Visit " + root.releasesUrl
                     : "")
            color: "#eaffff"
            wrapMode: Text.WordWrap
            font.pixelSize: 10
        }

        RowLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            spacing: 8

            Item { Layout.fillWidth: true }

            KeyCap {
                Layout.preferredWidth: 126
                Layout.fillHeight: true
                compact: true
                showBorders: root.appearanceStore.keyBordersVisible
                keyLabel: "OPEN RELEASES"
                accent: root.appearanceStore.primary
                toolTipText: "Open IMBOARD's GitHub releases page in your browser"
                onClicked: {
                    root.releaseOpenFailed = !Qt.openUrlExternally(root.releasesUrl)
                }
            }

            KeyCap {
                Layout.preferredWidth: 70
                Layout.fillHeight: true
                compact: true
                showBorders: root.appearanceStore.keyBordersVisible
                keyLabel: "CLOSE"
                accent: root.appearanceStore.secondary
                onClicked: root.close()
            }
        }
    }
}
