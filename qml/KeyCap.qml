// SPDX-FileCopyrightText: 2026 AnicetusCer
// SPDX-License-Identifier: GPL-3.0-or-later

import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Button {
    id: root
    required property string keyLabel
    property string subLabel: ""
    property string keyIcon: ""
    property string toolTipText: ""
    property string toolTipIcon: ""
    property color accent: "#48f3ff"
    property bool compact: false
    property bool showBorders: true
    property bool repeatEnabled: false
    readonly property bool hasSubLabel: subLabel.length > 0
    readonly property bool multiLineLabel: keyLabel.indexOf("\n") >= 0

    text: keyLabel
    font.pixelSize: compact ? 9 : Math.max(12, Math.min(18, height * 0.22))
    font.weight: Font.Medium
    hoverEnabled: true
    autoRepeat: repeatEnabled
    autoRepeatDelay: 420
    autoRepeatInterval: 55

    ToolTip {
        id: keyToolTip
        visible: root.toolTipText.length > 0 && (root.hovered || root.down)
        delay: 500
        timeout: 3500
        contentWidth: toolTipLabel.implicitWidth
                      + (root.toolTipIcon.length > 0 ? 37 : 0)
        contentHeight: Math.max(toolTipLabel.implicitHeight,
                                root.toolTipIcon.length > 0 ? 30 : 0)

        contentItem: RowLayout {
            spacing: 7

            Image {
                Layout.preferredWidth: 30
                Layout.preferredHeight: 30
                Layout.alignment: Qt.AlignVCenter
                source: root.toolTipIcon
                visible: root.toolTipIcon.length > 0
                fillMode: Image.PreserveAspectFit
                asynchronous: true
            }
            Text {
                id: toolTipLabel
                Layout.alignment: Qt.AlignVCenter
                text: root.toolTipText
                color: "#eaffff"
                font.pixelSize: 11
                style: Text.Outline
                styleColor: "#f0000000"
            }
        }

        background: Rectangle {
            radius: 7
            color: "#f00a1020"
            border.width: 2
            border.color: root.accent
        }
    }

    background: Item {
        Rectangle {
            anchors.fill: parent
            radius: root.compact ? 5 : 10
            color: "transparent"
            border.color: Qt.alpha(root.accent, root.down ? 0.75 : 0.28)
            border.width: root.showBorders ? root.compact ? 2 : (root.down ? 6 : 4) : 0
        }

        Rectangle {
            anchors.fill: parent
            anchors.margins: root.compact ? 2 : 3
            radius: root.compact ? 3 : 7
            color: root.down ? Qt.alpha(root.accent, 0.26)
                             : root.hovered ? Qt.alpha(root.accent, 0.10)
                                            : "transparent"
            border.color: root.accent
            border.width: root.showBorders ? root.compact ? 1 : (root.down ? 3 : 2) : 0
        }
    }

    contentItem: Item {
        Text {
            text: root.keyLabel
            visible: root.keyIcon.length === 0
            color: root.accent
            width: parent.width - 6
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
            wrapMode: Text.NoWrap
            x: Math.round(parent.width * (root.hasSubLabel ? 0.44 : 0.5) - width / 2)
            y: Math.round(parent.height * (root.hasSubLabel ? 0.58 : 0.5) - height / 2)
            font.pixelSize: root.compact ? 9
                            : root.multiLineLabel ? Math.max(7, Math.min(11, parent.height * 0.22))
                            : Math.max(10, Math.min(18,
                                                     parent.height * (root.hasSubLabel ? 0.30 : 0.38),
                                                     parent.width * (root.hasSubLabel ? 0.42 : 0.50)))
            font.weight: root.font.weight
            lineHeight: root.multiLineLabel ? 0.82 : 1.0
            style: Text.Outline
            styleColor: "#f0000000"
        }
        Image {
            anchors.centerIn: parent
            width: Math.min(38, parent.width - 10)
            height: Math.min(38, parent.height - 10)
            source: root.keyIcon
            visible: root.keyIcon.length > 0
            fillMode: Image.PreserveAspectFit
            asynchronous: true
        }
        Text {
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.margins: Math.max(1, Math.min(3, parent.height * 0.07))
            text: root.subLabel
            color: Qt.lighter(root.accent, 1.15)
            font.pixelSize: Math.max(6, Math.min(9, parent.height * 0.20,
                                                 parent.width * 0.24))
            style: Text.Outline
            styleColor: "#e0000000"
            visible: text.length > 0 && parent.width >= 18 && parent.height >= 18
        }
    }
}
