// SPDX-FileCopyrightText: 2026 AnicetusCer
// SPDX-License-Identifier: GPL-3.0-or-later

import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Window

Popup {
    id: root

    required property var appearanceStore
    required property var hostWindow
    required property var inputController
    required property bool portalBusy
    property real previousWindowHeight: -1

    objectName: "portalExplanationPopup"
    x: Math.round((parent.width - width) / 2)
    y: Math.round((parent.height - height) / 2)
    width: Math.min(800, parent.width - 40)
    height: Math.min(420, parent.height - 20)
    padding: 14
    modal: true
    dim: false
    closePolicy: Popup.NoAutoClose

    onOpened: {
        previousWindowHeight = hostWindow.height
        hostWindow.height = Math.min(Screen.height - 40,
                                     Math.max(hostWindow.height, 460))
    }
    onClosed: {
        if (previousWindowHeight > 0) {
            hostWindow.height = previousWindowHeight
            previousWindowHeight = -1
        }
    }

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
        spacing: 9
        Label {
            Layout.fillWidth: true
            text: "IMBOARD NEEDS YOUR PERMISSION TO WORK"
            color: root.appearanceStore.primary
            font.bold: true
            font.pixelSize: 13
            style: Text.Outline
            styleColor: "#f0000000"
        }
        Label {
            Layout.fillWidth: true
            Layout.fillHeight: true
            text: "Imboard uses on-screen buttons to send keyboard shortcuts and typed text to other apps.\n\n"
                  + "Modern Wayland desktops prevent ordinary apps from sending input to other apps. Flatpak also isolates applications by default. Linux desktop portals provide a standard, user-controlled way for applications to request specific access when needed.\n\n"
                  + "Imboard uses the XDG Remote Desktop portal because it provides a keyboard-control capability. Your system may therefore describe the request as Input Device, Remote Desktop, or Remote Control. This is expected and does not mean Imboard wants to view or remotely access your desktop.\n\n"
                  + "Imboard requests only keyboard control. It does not request screen sharing, mouse or pointer control, remote login, camera, location, or network access. The portal defines keyboard, pointer, and touchscreen as separate capabilities; Imboard requests only KEYBOARD.\n\n"
                  + "You can disconnect Imboard and delete its saved access token from CONFIG at any time. Your desktop's privacy settings may separately retain an inactive permission record.\n\n"
                  + "Now, armed with this knowledge, you can confidently choose SET UP to continue. When the system permission dialog appears, choose Allow and let the permission be retained across sessions."
            color: "#eaffff"
            font.pixelSize: 11
            wrapMode: Text.WordWrap
            verticalAlignment: Text.AlignVCenter
        }
        RowLayout {
            Layout.fillWidth: true
            Layout.preferredHeight: 34
            Label {
                Layout.fillWidth: true
                text: root.inputController.backendStatus
                color: root.inputController.backendReady
                       ? "#72ff9f" : root.appearanceStore.secondary
                font.pixelSize: 10
                elide: Text.ElideRight
            }
            KeyCap {
                Layout.preferredWidth: 90
                Layout.fillHeight: true
                showBorders: root.appearanceStore.keyBordersVisible
                keyLabel: "EXIT"
                accent: "#ff6d91"
                toolTipText: "Close Imboard without granting keyboard access"
                onClicked: Qt.quit()
            }
            KeyCap {
                Layout.preferredWidth: 120
                Layout.fillHeight: true
                showBorders: root.appearanceStore.keyBordersVisible
                keyLabel: root.portalBusy ? "WAIT" : "SET UP"
                accent: "#72ff9f"
                toolTipText: "Open the desktop permission window and request keyboard-only control"
                onClicked: {
                    if (!root.portalBusy)
                        root.inputController.connectPortal()
                }
            }
        }
    }
}
