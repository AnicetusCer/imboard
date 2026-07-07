// SPDX-FileCopyrightText: 2026 AnicetusCer
// SPDX-License-Identifier: GPL-3.0-or-later

import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Item {
    id: root

    required property var appearanceStore
    required property var customKeyStore
    required property var inputBackend
    required property var modifierSource

    property bool editMode: false
    property bool pickerOpen: false
    property int selectedSlot: -1
    property int currentPageIndex: 0
    property var draftAssignments: []
    property string pickerCategory: "all"

    // Static catalog data. Keep entries declarative: executable commands are
    // intentionally outside the custom-action model.
    readonly property var pickerCategories: [
        {label:"ALL", value:"all"},
        {label:"NAV", value:"nav"},
        {label:"F", value:"fkeys"},
        {label:"ABC", value:"abc"},
        {label:"SYM", value:"symbols"},
        {label:"DEV", value:"dev"},
        {label:"EMOJI", value:"emoji"},
        {label:"COMBO", value:"combos"}
    ]

    readonly property var pages: [
        { title: "NUM", controller: root, keys: [
            ["7","text","7"], ["8","text","8"], ["9","text","9"], ["↑","key","Up"],
            ["4","text","4"], ["5","text","5"], ["6","text","6"], ["←","key","Left"],
            ["1","text","1"], ["2","text","2"], ["3","text","3"], ["→","key","Right"],
            ["0","text","0"], [".","text","."], ["Del","key","Delete"], ["↓","key","Down"] ] },
        { title: "CODE", controller: root, keys: [
            ["|","text","|"], ["\\","text","\\"], ["`","text","`"], ["~","text","~"],
            ["(","text","("], [")","text",")"], ["[","text","["], ["]","text","]"],
            ["{","text","{"], ["}","text","}"], ["<","text","<"], [">","text",">"],
            ["$","text","$"], ["#","text","#"], ["&","text","&"], [";","text",";"] ] },
        { title: "MORE", controller: root, keys: [
            ["@","text","@"], ["%","text","%"], ["^","text","^"], ["*","text","*"],
            ["+","text","+"], ["-","text","-"], ["=","text","="], ["_","text","_"],
            ["'","text","'"], ["\"","text","\""], [":","text",":"], ["!","text","!"],
            ["?","text","?"], ["/","text","/"], [",","text",","], [".","text","."] ] },
        { title: "F-KEYS", controller: root, keys: [
            ["F1","key","F1"], ["F2","key","F2"], ["F3","key","F3"], ["F4","key","F4"],
            ["F5","key","F5"], ["F6","key","F6"], ["F7","key","F7"], ["F8","key","F8"],
            ["F9","key","F9"], ["F10","key","F10"], ["F11","key","F11"], ["F12","key","F12"],
            ["Esc","key","Escape"], ["Tab","key","Tab"], ["Home","key","Home"], ["End","key","End"],
            ["Caps","key","CapsLock"], ["Num","key","NumLock"], ["ScrLk","key","ScrollLock"], ["PrtSc","key","PrintScreen"] ] },
        { title: "COMBOS", controller: root, keys: [
            ["CPY","chord",["Ctrl"],"C","Copy — Ctrl+C"],
            ["PST","chord",["Ctrl"],"V","Paste — Ctrl+V"],
            ["CUT","chord",["Ctrl"],"X","Cut — Ctrl+X"],
            ["UND","chord",["Ctrl"],"Z","Undo — Ctrl+Z"],
            ["RDO","chord",["Ctrl","Shift"],"Z","Redo — Ctrl+Shift+Z"],
            ["SAV","chord",["Ctrl"],"S","Save — Ctrl+S"],
            ["FND","chord",["Ctrl"],"F","Find — Ctrl+F"],
            ["ALL","chord",["Ctrl"],"A","Select all — Ctrl+A"],
            ["N-TAB","chord",["Ctrl"],"T","New tab — Ctrl+T"],
            ["X-TAB","chord",["Ctrl"],"W","Close tab — Ctrl+W"],
            ["TERM","chord",["Ctrl","Alt"],"T","Terminal — Ctrl+Alt+T"],
            ["TASK","chord",["Alt"],"Tab","Task switch — Alt+Tab"] ] },
        { title: "CUSTOM", controller: root, keys: [] }
    ]

    readonly property var pickerKeys: [
        {label:"Esc", type:"key", value:"Escape", description:"Escape"},
        {label:"Tab", type:"key", value:"Tab", description:"Tab"},
        {label:"Bksp", type:"key", value:"Backspace", description:"Backspace"},
        {label:"Del", type:"key", value:"Delete", description:"Delete"},
        {label:"←", type:"key", value:"Left", description:"Left arrow"},
        {label:"↓", type:"key", value:"Down", description:"Down arrow"},
        {label:"↑", type:"key", value:"Up", description:"Up arrow"},
        {label:"→", type:"key", value:"Right", description:"Right arrow"},
        {label:"Home", type:"key", value:"Home", description:"Home"},
        {label:"End", type:"key", value:"End", description:"End"},
        {label:"PgUp", type:"key", value:"PageUp", description:"Page Up"},
        {label:"PgDn", type:"key", value:"PageDown", description:"Page Down"},
        {label:"Enter", type:"key", value:"Enter", description:"Enter"},
        {label:"Space", type:"key", value:"Space", description:"Space bar"},
        {label:"Ins", type:"key", value:"Insert", description:"Insert"},
        {label:"Caps", type:"key", value:"CapsLock", description:"Caps Lock"},
        {label:"Num", type:"key", value:"NumLock", description:"Num Lock"},
        {label:"ScrLk", type:"key", value:"ScrollLock", description:"Scroll Lock"},
        {label:"PrtSc", type:"key", value:"PrintScreen", description:"Print Screen"},
        {label:"Pause", type:"key", value:"Pause", description:"Pause / Break"},
        {label:"Menu", type:"key", value:"Menu", description:"Context menu key"},
        {label:"F1", type:"key", value:"F1", description:"Function key F1"},
        {label:"F2", type:"key", value:"F2", description:"Function key F2"},
        {label:"F3", type:"key", value:"F3", description:"Function key F3"},
        {label:"F4", type:"key", value:"F4", description:"Function key F4"},
        {label:"F5", type:"key", value:"F5", description:"Function key F5"},
        {label:"F6", type:"key", value:"F6", description:"Function key F6"},
        {label:"F7", type:"key", value:"F7", description:"Function key F7"},
        {label:"F8", type:"key", value:"F8", description:"Function key F8"},
        {label:"F9", type:"key", value:"F9", description:"Function key F9"},
        {label:"F10", type:"key", value:"F10", description:"Function key F10"},
        {label:"F11", type:"key", value:"F11", description:"Function key F11"},
        {label:"F12", type:"key", value:"F12", description:"Function key F12"},
        {label:"0", type:"key", value:"0", description:"0 key"},
        {label:"1", type:"key", value:"1", description:"1 key"},
        {label:"2", type:"key", value:"2", description:"2 key"},
        {label:"3", type:"key", value:"3", description:"3 key"},
        {label:"4", type:"key", value:"4", description:"4 key"},
        {label:"5", type:"key", value:"5", description:"5 key"},
        {label:"6", type:"key", value:"6", description:"6 key"},
        {label:"7", type:"key", value:"7", description:"7 key"},
        {label:"8", type:"key", value:"8", description:"8 key"},
        {label:"9", type:"key", value:"9", description:"9 key"},
        {label:"A", type:"key", value:"A", description:"A key"},
        {label:"B", type:"key", value:"B", description:"B key"},
        {label:"C", type:"key", value:"C", description:"C key"},
        {label:"D", type:"key", value:"D", description:"D key"},
        {label:"E", type:"key", value:"E", description:"E key"},
        {label:"F", type:"key", value:"F", description:"F key"},
        {label:"G", type:"key", value:"G", description:"G key"},
        {label:"H", type:"key", value:"H", description:"H key"},
        {label:"I", type:"key", value:"I", description:"I key"},
        {label:"J", type:"key", value:"J", description:"J key"},
        {label:"K", type:"key", value:"K", description:"K key"},
        {label:"L", type:"key", value:"L", description:"L key"},
        {label:"M", type:"key", value:"M", description:"M key"},
        {label:"N", type:"key", value:"N", description:"N key"},
        {label:"O", type:"key", value:"O", description:"O key"},
        {label:"P", type:"key", value:"P", description:"P key"},
        {label:"Q", type:"key", value:"Q", description:"Q key"},
        {label:"R", type:"key", value:"R", description:"R key"},
        {label:"S", type:"key", value:"S", description:"S key"},
        {label:"T", type:"key", value:"T", description:"T key"},
        {label:"U", type:"key", value:"U", description:"U key"},
        {label:"V", type:"key", value:"V", description:"V key"},
        {label:"W", type:"key", value:"W", description:"W key"},
        {label:"X", type:"key", value:"X", description:"X key"},
        {label:"Y", type:"key", value:"Y", description:"Y key"},
        {label:"Z", type:"key", value:"Z", description:"Z key"},
        {label:"|", type:"text", value:"|", description:"Pipe"},
        {label:"\\", type:"text", value:"\\", description:"Backslash"},
        {label:"`", type:"text", value:"`", description:"Backtick"},
        {label:"~", type:"text", value:"~", description:"Tilde"},
        {label:"{", type:"text", value:"{", description:"Opening brace"},
        {label:"}", type:"text", value:"}", description:"Closing brace"},
        {label:"[", type:"text", value:"[", description:"Opening bracket"},
        {label:"]", type:"text", value:"]", description:"Closing bracket"},
        {label:"<", type:"text", value:"<", description:"Less than"},
        {label:">", type:"text", value:">", description:"Greater than"},
        {label:"$", type:"text", value:"$", description:"Dollar"},
        {label:"#", type:"text", value:"#", description:"Hash"},
        {label:"&", type:"text", value:"&", description:"Ampersand"},
        {label:"(", type:"text", value:"(", description:"Opening parenthesis"},
        {label:")", type:"text", value:")", description:"Closing parenthesis"},
        {label:"@", type:"text", value:"@", description:"At sign"},
        {label:"%", type:"text", value:"%", description:"Percent"},
        {label:"^", type:"text", value:"^", description:"Caret"},
        {label:"*", type:"text", value:"*", description:"Asterisk"},
        {label:"+", type:"text", value:"+", description:"Plus"},
        {label:"-", type:"text", value:"-", description:"Minus"},
        {label:"=", type:"text", value:"=", description:"Equals"},
        {label:"_", type:"text", value:"_", description:"Underscore"},
        {label:"'", type:"text", value:"'", description:"Single quote"},
        {label:"\"", type:"text", value:"\"", description:"Double quote"},
        {label:":", type:"text", value:":", description:"Colon"},
        {label:";", type:"text", value:";", description:"Semicolon"},
        {label:"!", type:"text", value:"!", description:"Exclamation mark"},
        {label:"?", type:"text", value:"?", description:"Question mark"},
        {label:"/", type:"text", value:"/", description:"Slash"},
        {label:",", type:"text", value:",", description:"Comma"},
        {label:".", type:"text", value:".", description:"Period"},
        {label:"£", type:"text", value:"£", description:"Pound sterling"},
        {label:"€", type:"text", value:"€", description:"Euro"},
        {label:"¥", type:"text", value:"¥", description:"Yen / yuan"},
        {label:"©", type:"text", value:"©", description:"Copyright"},
        {label:"®", type:"text", value:"®", description:"Registered trademark"},
        {label:"°", type:"text", value:"°", description:"Degree sign"},
        {label:"±", type:"text", value:"±", description:"Plus or minus"},
        {label:"…", type:"text", value:"…", description:"Ellipsis"},
        {label:"=>", type:"text", value:"=>", category:"token",
         description:"Fat arrow — commonly used by JavaScript and match expressions"},
        {label:"->", type:"text", value:"->", category:"token",
         description:"Thin arrow — member access, return types and lambdas"},
        {label:"!=", type:"text", value:"!=", category:"token",
         description:"Not equal operator"},
        {label:"==", type:"text", value:"==", category:"token",
         description:"Equality operator"},
        {label:"===", type:"text", value:"===", category:"token",
         description:"Strict equality operator"},
        {label:"&&", type:"text", value:"&&", category:"token",
         description:"Logical AND / shell command chaining"},
        {label:"||", type:"text", value:"||", category:"token",
         description:"Logical OR / shell fallback"},
        {label:"::", type:"text", value:"::", category:"token",
         description:"Scope or namespace separator"},
        {label:":=", type:"text", value:":=", category:"token",
         description:"Assignment expression"},
        {label:"??", type:"text", value:"??", category:"token",
         description:"Null-coalescing operator"},
        {label:"?.", type:"text", value:"?.", category:"token",
         description:"Optional chaining operator"},
        {label:"//", type:"text", value:"//", category:"token",
         description:"Line comment marker"},
        {label:"/*", type:"text", value:"/*", category:"token",
         description:"Block comment opening marker"},
        {label:"*/", type:"text", value:"*/", category:"token",
         description:"Block comment closing marker"},
        {label:"<!--", type:"text", value:"<!--", category:"token",
         description:"HTML comment opening marker"},
        {label:"-->", type:"text", value:"-->", category:"token",
         description:"HTML comment closing marker"},
        {label:"${}", type:"text", value:"${}", category:"token",
         description:"Template or shell interpolation braces"},
        {label:"$()", type:"text", value:"$()", category:"token",
         description:"Shell command substitution"},
        {label:"UP", type:"text", value:"👍", category:"emoji", description:"Emoji — thumbs up",
         icon:"qrc:/Imboard/assets/twemoji/1f44d.png"},
        {label:"DOWN", type:"text", value:"👎", category:"emoji", description:"Emoji — thumbs down",
         icon:"qrc:/Imboard/assets/twemoji/1f44e.png"},
        {label:"OK", type:"text", value:"✅", category:"emoji", description:"Emoji — completed / approved",
         icon:"qrc:/Imboard/assets/twemoji/2705.png"},
        {label:"NO", type:"text", value:"❌", category:"emoji", description:"Emoji — failed / rejected",
         icon:"qrc:/Imboard/assets/twemoji/274c.png"},
        {label:"WARN", type:"text", value:"⚠️", category:"emoji", description:"Emoji — warning",
         icon:"qrc:/Imboard/assets/twemoji/26a0.png"},
        {label:"BUG", type:"text", value:"🐛", category:"emoji", description:"Emoji — bug",
         icon:"qrc:/Imboard/assets/twemoji/1f41b.png"},
        {label:"TOOLS", type:"text", value:"🛠️", category:"emoji", description:"Emoji — tools / work in progress",
         icon:"qrc:/Imboard/assets/twemoji/1f6e0.png"},
        {label:"IDEA", type:"text", value:"💡", category:"emoji", description:"Emoji — idea",
         icon:"qrc:/Imboard/assets/twemoji/1f4a1.png"},
        {label:"SHIP", type:"text", value:"🚀", category:"emoji", description:"Emoji — launch / deploy",
         icon:"qrc:/Imboard/assets/twemoji/1f680.png"},
        {label:"HOT", type:"text", value:"🔥", category:"emoji", description:"Emoji — hot / important",
         icon:"qrc:/Imboard/assets/twemoji/1f525.png"},
        {label:"PARTY", type:"text", value:"🎉", category:"emoji", description:"Emoji — celebration",
         icon:"qrc:/Imboard/assets/twemoji/1f389.png"},
        {label:"LOVE", type:"text", value:"❤️", category:"emoji", description:"Emoji — heart",
         icon:"qrc:/Imboard/assets/twemoji/2764.png"},
        {label:"LOL", type:"text", value:"😂", category:"emoji", description:"Emoji — laughing",
         icon:"qrc:/Imboard/assets/twemoji/1f602.png"},
        {label:"THINK", type:"text", value:"🤔", category:"emoji", description:"Emoji — thinking",
         icon:"qrc:/Imboard/assets/twemoji/1f914.png"},
        {label:"LOOK", type:"text", value:"👀", category:"emoji", description:"Emoji — reviewing / looking",
         icon:"qrc:/Imboard/assets/twemoji/1f440.png"},
        {label:"PIN", type:"text", value:"📌", category:"emoji", description:"Emoji — pinned / important",
         icon:"qrc:/Imboard/assets/twemoji/1f4cc.png"},
        {label:"CPY", type:"chord", modifiers:["Ctrl"], key:"C",
         description:"Copy — Ctrl+C"},
        {label:"PST", type:"chord", modifiers:["Ctrl"], key:"V",
         description:"Paste — Ctrl+V"},
        {label:"CUT", type:"chord", modifiers:["Ctrl"], key:"X",
         description:"Cut — Ctrl+X"},
        {label:"UND", type:"chord", modifiers:["Ctrl"], key:"Z",
         description:"Undo — Ctrl+Z"},
        {label:"RDO", type:"chord", modifiers:["Ctrl","Shift"], key:"Z",
         description:"Redo — Ctrl+Shift+Z"},
        {label:"SAV", type:"chord", modifiers:["Ctrl"], key:"S",
         description:"Save — Ctrl+S"},
        {label:"FND", type:"chord", modifiers:["Ctrl"], key:"F",
         description:"Find — Ctrl+F"},
        {label:"ALL", type:"chord", modifiers:["Ctrl"], key:"A",
         description:"Select all — Ctrl+A"},
        {label:"N-TAB", type:"chord", modifiers:["Ctrl"], key:"T",
         description:"New tab — Ctrl+T"},
        {label:"X-TAB", type:"chord", modifiers:["Ctrl"], key:"W",
         description:"Close tab — Ctrl+W"},
        {label:"TERM", type:"chord", modifiers:["Ctrl","Alt"], key:"T",
         description:"Open terminal — Ctrl+Alt+T"},
        {label:"TASK", type:"chord", modifiers:["Alt"], key:"Tab",
         description:"Switch task — Alt+Tab"},
        {label:"TOP", type:"chord", modifiers:["Ctrl"], key:"Home",
         description:"Document start — Ctrl+Home"},
        {label:"BOT", type:"chord", modifiers:["Ctrl"], key:"End",
         description:"Document end — Ctrl+End"},
        {label:"P-WRD", type:"chord", modifiers:["Ctrl"], key:"Left",
         description:"Previous word — Ctrl+Left"},
        {label:"N-WRD", type:"chord", modifiers:["Ctrl"], key:"Right",
         description:"Next word — Ctrl+Right"},
        {label:"D-BK", type:"chord", modifiers:["Ctrl"], key:"Backspace",
         description:"Delete previous word — Ctrl+Backspace"},
        {label:"D-FWD", type:"chord", modifiers:["Ctrl"], key:"Delete",
         description:"Delete next word — Ctrl+Delete"},
        {label:"CTRL\nPGUP", type:"chord", modifiers:["Ctrl"], key:"PageUp",
         description:"Previous tab or page — Ctrl+PageUp"},
        {label:"CTRL\nPGDN", type:"chord", modifiers:["Ctrl"], key:"PageDown",
         description:"Next tab or page — Ctrl+PageDown"},
        {label:"CTRL\nUP", type:"chord", modifiers:["Ctrl"], key:"Up",
         description:"Generic navigation — Ctrl+Up"},
        {label:"CTRL\nDOWN", type:"chord", modifiers:["Ctrl"], key:"Down",
         description:"Generic navigation — Ctrl+Down"},
        {label:"S-HOME", type:"chord", modifiers:["Shift"], key:"Home",
         description:"Select to line start — Shift+Home"},
        {label:"S-END", type:"chord", modifiers:["Shift"], key:"End",
         description:"Select to line end — Shift+End"},
        {label:"SH\nLEFT", type:"chord", modifiers:["Shift"], key:"Left",
         description:"Select previous character — Shift+Left"},
        {label:"SH\nRIGHT", type:"chord", modifiers:["Shift"], key:"Right",
         description:"Select next character — Shift+Right"},
        {label:"SH\nUP", type:"chord", modifiers:["Shift"], key:"Up",
         description:"Extend selection up — Shift+Up"},
        {label:"SH\nDOWN", type:"chord", modifiers:["Shift"], key:"Down",
         description:"Extend selection down — Shift+Down"},
        {label:"SH\nTAB", type:"chord", modifiers:["Shift"], key:"Tab",
         description:"Reverse focus or outdent — Shift+Tab"},
        {label:"SH\nENTER", type:"chord", modifiers:["Shift"], key:"Enter",
         description:"Generic shortcut — Shift+Enter"},
        {label:"SH\nDEL", type:"chord", modifiers:["Shift"], key:"Delete",
         description:"Generic shortcut — Shift+Delete"},
        {label:"ALT\nQ", type:"chord", modifiers:["Alt"], key:"Q",
         description:"Generic shortcut — Alt+Q"},
        {label:"ALT\nSH\nQ", type:"chord", modifiers:["Alt","Shift"], key:"Q",
         description:"Generic shortcut — Alt+Shift+Q"},
        {label:"ALT\nP", type:"chord", modifiers:["Alt"], key:"P",
         description:"Generic shortcut — Alt+P"},
        {label:"ALT\nSH\nP", type:"chord", modifiers:["Alt","Shift"], key:"P",
         description:"Generic shortcut — Alt+Shift+P"},
        {label:"ALT\nF", type:"chord", modifiers:["Alt"], key:"F",
         description:"Generic shortcut — Alt+F"},
        {label:"ALT\nSH\nF", type:"chord", modifiers:["Alt","Shift"], key:"F",
         description:"Generic shortcut — Alt+Shift+F"},
        {label:"ALT\nE", type:"chord", modifiers:["Alt"], key:"E",
         description:"Generic shortcut — Alt+E"},
        {label:"ALT\nSH\nE", type:"chord", modifiers:["Alt","Shift"], key:"E",
         description:"Generic shortcut — Alt+Shift+E"},
        {label:"ALT\nR", type:"chord", modifiers:["Alt"], key:"R",
         description:"Generic shortcut — Alt+R"},
        {label:"ALT\nSH\nR", type:"chord", modifiers:["Alt","Shift"], key:"R",
         description:"Generic shortcut — Alt+Shift+R"},
        {label:"ALT\nS", type:"chord", modifiers:["Alt"], key:"S",
         description:"Generic shortcut — Alt+S"},
        {label:"ALT\nSH\nS", type:"chord", modifiers:["Alt","Shift"], key:"S",
         description:"Generic shortcut — Alt+Shift+S"},
        {label:"ALT\nW", type:"chord", modifiers:["Alt"], key:"W",
         description:"Generic shortcut — Alt+W"},
        {label:"ALT\nSH\nW", type:"chord", modifiers:["Alt","Shift"], key:"W",
         description:"Generic shortcut — Alt+Shift+W"},
        {label:"ALT\nA", type:"chord", modifiers:["Alt"], key:"A",
         description:"Generic shortcut — Alt+A"},
        {label:"ALT\nSH\nA", type:"chord", modifiers:["Alt","Shift"], key:"A",
         description:"Generic shortcut — Alt+Shift+A"},
        {label:"ALT\nD", type:"chord", modifiers:["Alt"], key:"D",
         description:"Generic shortcut — Alt+D"},
        {label:"ALT\nSH\nD", type:"chord", modifiers:["Alt","Shift"], key:"D",
         description:"Generic shortcut — Alt+Shift+D"},
        {label:"ALT\nX", type:"chord", modifiers:["Alt"], key:"X",
         description:"Generic shortcut — Alt+X"},
        {label:"ALT\nSH\nX", type:"chord", modifiers:["Alt","Shift"], key:"X",
         description:"Generic shortcut — Alt+Shift+X"},
        {label:"ALT\nF4", type:"chord", modifiers:["Alt"], key:"F4",
         description:"Close window — Alt+F4"},
        {label:"ALT\nSPACE", type:"chord", modifiers:["Alt"], key:"Space",
         description:"Window menu — Alt+Space"},
        {label:"ALT\nESC", type:"chord", modifiers:["Alt"], key:"Escape",
         description:"Cycle windows — Alt+Escape"},
        {label:"ALT\nLEFT", type:"chord", modifiers:["Alt"], key:"Left",
         description:"Navigate back — Alt+Left"},
        {label:"ALT\nRIGHT", type:"chord", modifiers:["Alt"], key:"Right",
         description:"Navigate forward — Alt+Right"},
        {label:"ALT\nUP", type:"chord", modifiers:["Alt"], key:"Up",
         description:"Generic shortcut — Alt+Up"},
        {label:"ALT\nDOWN", type:"chord", modifiers:["Alt"], key:"Down",
         description:"Generic shortcut — Alt+Down"},
        {label:"ALT\nSH\nUP", type:"chord", modifiers:["Alt","Shift"], key:"Up",
         description:"Generic shortcut — Alt+Shift+Up"},
        {label:"ALT\nSH\nDOWN", type:"chord", modifiers:["Alt","Shift"], key:"Down",
         description:"Generic shortcut — Alt+Shift+Down"},
        {label:"CTRL\nSH\nLEFT", type:"chord", modifiers:["Ctrl","Shift"], key:"Left",
         description:"Select previous word — Ctrl+Shift+Left"},
        {label:"CTRL\nSH\nRIGHT", type:"chord", modifiers:["Ctrl","Shift"], key:"Right",
         description:"Select next word — Ctrl+Shift+Right"},
        {label:"CTRL\nSH\nHOME", type:"chord", modifiers:["Ctrl","Shift"], key:"Home",
         description:"Select to document start — Ctrl+Shift+Home"},
        {label:"CTRL\nSH\nEND", type:"chord", modifiers:["Ctrl","Shift"], key:"End",
         description:"Select to document end — Ctrl+Shift+End"},
        {label:"CTRL\nSH\nUP", type:"chord", modifiers:["Ctrl","Shift"], key:"Up",
         description:"Generic selection/navigation — Ctrl+Shift+Up"},
        {label:"CTRL\nSH\nDOWN", type:"chord", modifiers:["Ctrl","Shift"], key:"Down",
         description:"Generic selection/navigation — Ctrl+Shift+Down"},
        {label:"CTRL\nALT\nQ", type:"chord", modifiers:["Ctrl","Alt"], key:"Q",
         description:"Generic shortcut — Ctrl+Alt+Q"},
        {label:"CTRL\nALT\nC", type:"chord", modifiers:["Ctrl","Alt"], key:"C",
         description:"Generic shortcut — Ctrl+Alt+C"},
        {label:"CTRL\nALT\nD", type:"chord", modifiers:["Ctrl","Alt"], key:"D",
         description:"Generic shortcut — Ctrl+Alt+D"},
        {label:"CTRL\nALT\nF", type:"chord", modifiers:["Ctrl","Alt"], key:"F",
         description:"Generic shortcut — Ctrl+Alt+F"},
        {label:"CTRL\nALT\nDEL", type:"chord", modifiers:["Ctrl","Alt"], key:"Delete",
         description:"System/session shortcut — Ctrl+Alt+Delete"},
        {label:"CTRL\nALT\nBKSP", type:"chord", modifiers:["Ctrl","Alt"], key:"Backspace",
         description:"System/session shortcut — Ctrl+Alt+Backspace"},
        {label:"CTRL\nALT\nESC", type:"chord", modifiers:["Ctrl","Alt"], key:"Escape",
         description:"System/window shortcut — Ctrl+Alt+Escape"},
        {label:"CTRL\nALT\nLEFT", type:"chord", modifiers:["Ctrl","Alt"], key:"Left",
         description:"Workspace/navigation shortcut — Ctrl+Alt+Left"},
        {label:"CTRL\nALT\nRIGHT", type:"chord", modifiers:["Ctrl","Alt"], key:"Right",
         description:"Workspace/navigation shortcut — Ctrl+Alt+Right"},
        {label:"CTRL\nALT\nUP", type:"chord", modifiers:["Ctrl","Alt"], key:"Up",
         description:"Workspace/navigation shortcut — Ctrl+Alt+Up"},
        {label:"CTRL\nALT\nDOWN", type:"chord", modifiers:["Ctrl","Alt"], key:"Down",
         description:"Workspace/navigation shortcut — Ctrl+Alt+Down"},
        {label:"CTRL\nSH\nP", type:"chord", modifiers:["Ctrl","Shift"], key:"P",
         description:"Generic shortcut — Ctrl+Shift+P"},
        {label:"CTRL\nSH\nE", type:"chord", modifiers:["Ctrl","Shift"], key:"E",
         description:"Generic shortcut — Ctrl+Shift+E"},
        {label:"CTRL\nSH\nG", type:"chord", modifiers:["Ctrl","Shift"], key:"G",
         description:"Generic shortcut — Ctrl+Shift+G"},
        {label:"CTRL\nSH\nH", type:"chord", modifiers:["Ctrl","Shift"], key:"H",
         description:"Generic shortcut — Ctrl+Shift+H"},
        {label:"CTRL\nSH\nO", type:"chord", modifiers:["Ctrl","Shift"], key:"O",
         description:"Generic shortcut — Ctrl+Shift+O"},
        {label:"CTRL\nSH\nF", type:"chord", modifiers:["Ctrl","Shift"], key:"F",
         description:"Generic shortcut — Ctrl+Shift+F"},
        {label:"CTRL\nSH\nT", type:"chord", modifiers:["Ctrl","Shift"], key:"T",
         description:"Generic shortcut — Ctrl+Shift+T"},
        {label:"CTRL\nSH\nW", type:"chord", modifiers:["Ctrl","Shift"], key:"W",
         description:"Generic shortcut — Ctrl+Shift+W"},
        {label:"ALT\nENTER", type:"chord", modifiers:["Alt"], key:"Enter",
         description:"Generic shortcut — Alt+Enter"}
    ]

    // Filtering and action dispatch.
    readonly property var filteredPickerKeys: pickerKeys.filter(function(key) {
        return root.pickerCategory === "all"
                || root.categoryForKey(key) === root.pickerCategory
    })
    readonly property var filteredPickerChoices: filteredPickerKeys.map(function(key) {
        return {key:key, controller: root}
    })
    readonly property var pickerCategoryChoices: pickerCategories.map(function(category) {
        return {category:category, controller: root}
    })
    readonly property var pageDotChoices: [
        {index:0, controller: root},
        {index:1, controller: root},
        {index:2, controller: root},
        {index:3, controller: root},
        {index:4, controller: root},
        {index:5, controller: root}
    ]

    function categoryForKey(key) {
        if (key.type === "chord") return "combos"
        if (key.category === "emoji") return "emoji"
        if (key.category === "token") return "dev"
        if (key.type === "text") return "symbols"
        if (key.value.length === 1) return "abc"
        if (key.value.length > 1 && key.value.charAt(0) === "F"
                && !isNaN(Number(key.value.substring(1)))) return "fkeys"
        return "nav"
    }

    function repeatableAction(action) {
        return action[1] === "key" && modifierSource.repeatableKey(action[2])
               && !modifierSource.repeatBlockingModifierActive()
    }

    function repeatableAssignment(assignment) {
        return assignment && assignment.type === "key"
               && modifierSource.repeatableKey(assignment.value)
               && !modifierSource.repeatBlockingModifierActive()
    }

    function activeKeyModifiers() {
        const modifiers = []
        if (modifierSource.controlHeld) modifiers.push("Ctrl")
        if (modifierSource.altHeld) modifiers.push("Alt")
        if (modifierSource.metaHeld) modifiers.push("Meta")
        if (modifierSource.shifted) modifiers.push("Shift")
        return modifiers
    }

    function sendKeyWithActiveModifiers(value) {
        const modifiers = activeKeyModifiers()
        if (modifiers.length > 0) inputBackend.sendChord(modifiers, value)
        else inputBackend.sendKey(value)
        modifierSource.clearOneShotShift()
    }

    function trigger(action) {
        if (action[1] === "text") inputBackend.sendText(action[2])
        else if (action[1] === "key") sendKeyWithActiveModifiers(action[2])
        else if (action[1] === "chord") inputBackend.sendChord(action[2], action[3])
    }

    function triggerAssignment(assignment) {
        if (!assignment || !assignment.type) return
        if (assignment.type === "text") inputBackend.sendText(assignment.value)
        else if (assignment.type === "key") sendKeyWithActiveModifiers(assignment.value)
        else if (assignment.type === "chord")
            inputBackend.sendChord(assignment.modifiers, assignment.key)
    }

    function copyAssignments() {
        const copy = []
        for (let index = 0; index < customKeyStore.assignments.length; ++index) {
            const item = customKeyStore.assignments[index]
            copy.push({label:item.label, type:item.type, value:item.value,
                       modifiers:item.modifiers, key:item.key,
                       icon:item.icon,
                       description:item.description})
        }
        return copy
    }

    function toggleSetMode() {
        if (!editMode) {
            draftAssignments = copyAssignments()
            editMode = true
            pickerOpen = false
            selectedSlot = -1
            return
        }
        if (customKeyStore.commit(draftAssignments)) {
            editMode = false
            pickerOpen = false
            selectedSlot = -1
        }
    }

    function cancelEditing() {
        draftAssignments = []
        editMode = false
        pickerOpen = false
        selectedSlot = -1
    }

    function chooseKey(key) {
        if (selectedSlot < 0) return
        const next = draftAssignments.slice()
        next[selectedSlot] = {label:key.label, type:key.type, value:key.value,
                              modifiers:key.modifiers, key:key.key,
                              icon:key.icon,
                              description:key.description}
        draftAssignments = next
        customKeyPicker.close()
        pickerOpen = false
    }

    function openCustomKeyPicker() {
        customKeyPicker.open()
    }

    function closeCustomKeyPicker() {
        customKeyPicker.close()
    }

    function resetAvailableKeyGrid() {
        availableKeyGrid.positionViewAtBeginning()
    }

    function setPageIndex(index) {
        currentPageIndex = index
    }

    function clearSlot(slot) {
        const next = draftAssignments.slice()
        next[slot] = {label:"", type:"", value:"", description:"Unassigned"}
        draftAssignments = next
    }

    // Custom-key picker shared by the swipe-page components.
    Popup {
        id: customKeyPicker
        objectName: "customKeyPicker"
        parent: Overlay.overlay
        x: Math.round((parent.width - width) / 2)
        y: Math.round((parent.height - height) / 2)
        width: Math.max(620, Math.min(760, parent.width - 36))
        height: Math.max(180, Math.min(280, parent.height - 36))
        padding: 10
        modal: true
        dim: false
        closePolicy: Popup.NoAutoClose
        onClosed: root.pickerOpen = false

        background: Rectangle {
            radius: 12
            color: "#e00a1020"
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

        contentItem: Item {
            RowLayout {
                id: pickerHeader
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.top: parent.top
                height: 26

                Label {
                    Layout.fillWidth: true
                    text: "SELECT KEY FOR CUSTOM SLOT " + (root.selectedSlot + 1)
                    color: root.appearanceStore.secondary
                    font.pixelSize: 11
                    font.bold: true
                    style: Text.Outline
                    styleColor: "#f0000000"
                }
                KeyCap {
                    Layout.preferredWidth: 58
                    Layout.fillHeight: true
                    keyLabel: "BACK"
                    accent: "#ff6d91"
                    compact: true
                    showBorders: root.appearanceStore.keyBordersVisible
                    toolTipText: "Return without changing this slot"
                    onClicked: customKeyPicker.close()
                }
            }

            RowLayout {
                id: pickerCategoryBar
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.top: pickerHeader.bottom
                anchors.topMargin: 5
                height: 22
                spacing: 3

                Repeater {
                    model: root.pickerCategoryChoices
                    KeyCap {
                        id: pickerCategoryKey
                        required property var modelData
                        readonly property var category: modelData.category
                        readonly property var controller: modelData.controller
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        compact: true
                        showBorders: pickerCategoryKey.controller.appearanceStore.keyBordersVisible
                        keyLabel: pickerCategoryKey.category.label
                        accent: pickerCategoryKey.controller.pickerCategory === pickerCategoryKey.category.value
                                ? "#ffffff" : pickerCategoryKey.controller.appearanceStore.primary
                        toolTipText: "Show " + pickerCategoryKey.category.label.toLowerCase() + " choices"
                        onClicked: {
                            pickerCategoryKey.controller.pickerCategory = pickerCategoryKey.category.value
                            pickerCategoryKey.controller.resetAvailableKeyGrid()
                        }
                    }
                }
            }

            GridView {
                id: availableKeyGrid
                objectName: "availableKeyGrid"
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.top: pickerCategoryBar.bottom
                anchors.bottom: parent.bottom
                anchors.topMargin: 6
                clip: true
                cellWidth: width / 8
                cellHeight: 48
                model: root.filteredPickerChoices
                boundsBehavior: Flickable.StopAtBounds
                ScrollBar.vertical: ScrollBar {
                    policy: ScrollBar.AlwaysOn
                }

                delegate: Item {
                    id: availableKey
                    required property var modelData
                    readonly property var keyData: modelData.key
                    readonly property var controller: modelData.controller
                    width: GridView.view.cellWidth
                    height: GridView.view.cellHeight
                    KeyCap {
                        anchors.fill: parent
                        anchors.margins: 2
                        showBorders: availableKey.controller.appearanceStore.keyBordersVisible
                        keyLabel: availableKey.keyData.label
                        keyIcon: availableKey.keyData.icon || ""
                        accent: availableKey.keyData.type === "chord"
                                ? availableKey.controller.appearanceStore.secondary
                                : availableKey.keyData.category === "token" ? "#72ff9f"
                                : availableKey.keyData.category === "emoji" ? "#ffd166"
                                : availableKey.controller.appearanceStore.primary
                        toolTipText: availableKey.keyData.description
                        toolTipIcon: availableKey.keyData.icon || ""
                        onClicked: availableKey.controller.chooseKey(availableKey.keyData)
                    }
                }
            }
        }
    }

    ColumnLayout {
        anchors.fill: parent
        spacing: 4

        RowLayout {
            Layout.fillWidth: true
            Layout.preferredHeight: 24
            Label {
                Layout.fillWidth: true
                text: root.pickerOpen
                      ? "CUSTOM / PICK KEY" : root.pages[root.currentPageIndex].title
                color: root.appearanceStore.secondary
                font.bold: true
                style: Text.Outline
                styleColor: "#f0000000"
            }

            Row {
                spacing: 6

                Repeater {
                    model: root.pageDotChoices

                    Rectangle {
                        id: pageIndicatorDot

                        required property var modelData

                        readonly property int pageIndex: modelData.index
                        readonly property var controller: modelData.controller

                        width: 9
                        height: 9
                        radius: width / 2
                        color: pageIndicatorDot.pageIndex === pageIndicatorDot.controller.currentPageIndex
                               ? pageIndicatorDot.controller.appearanceStore.secondary : "transparent"
                        border.width: 1
                        border.color: pageIndicatorDot.pageIndex === pageIndicatorDot.controller.currentPageIndex
                                      ? "#ffffff" : pageIndicatorDot.controller.appearanceStore.primary

                        MouseArea {
                            anchors.fill: parent
                            enabled: !pageIndicatorDot.controller.pickerOpen
                            onClicked: pageIndicatorDot.controller.setPageIndex(pageIndicatorDot.pageIndex)
                        }
                    }
                }
            }
        }

        SwipeView {
            id: view
            Layout.fillWidth: true
            Layout.fillHeight: true
            clip: true
            interactive: !root.pickerOpen
            currentIndex: root.currentPageIndex
            onCurrentIndexChanged: root.currentPageIndex = view.currentIndex

            Repeater {
                model: root.pages
                Loader {
                    required property var modelData
                    property var pageData: modelData
                    source: pageData.title === "CUSTOM"
                            ? "DeveloperCustomPage.qml" : "DeveloperStandardPage.qml"
                    onLoaded: item.pageData = pageData
                }
            }
        }
    }
}
