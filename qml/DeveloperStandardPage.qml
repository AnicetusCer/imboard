// SPDX-FileCopyrightText: 2026 AnicetusCer
// SPDX-License-Identifier: GPL-3.0-or-later

import QtQuick
import QtQuick.Layouts

GridLayout {
    id: root

    property var pageData: ({controller:null, keys:[]})

    readonly property var keyChoices: pageData.keys.map(function(keyAction) {
        return {keyAction:keyAction, controller: root.pageData.controller}
    })

    columns: 4
    rowSpacing: 4
    columnSpacing: 4

    Repeater {
        model: root.keyChoices

        KeyCap {
            id: standardKey

            required property var modelData

            readonly property var keyAction: modelData.keyAction
            readonly property var controller: modelData.controller

            Layout.fillWidth: true
            Layout.fillHeight: true
            showBorders: standardKey.controller.appearanceStore.keyBordersVisible
            keyLabel: standardKey.keyAction[0]
            accent: standardKey.controller.appearanceStore.primary
            toolTipText: standardKey.keyAction.length > 4 ? standardKey.keyAction[4] : ""
            repeatEnabled: standardKey.controller.repeatableAction(standardKey.keyAction)
            onClicked: standardKey.controller.trigger(standardKey.keyAction)
        }
    }
}
