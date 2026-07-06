# Imboard privacy notes

Imboard is an on-screen keyboard. Its core permission is intentionally narrow,
but it is still sensitive because it allows Imboard to send keyboard input to
other applications.

## Permissions

The Flatpak development manifest does not request network access or host
filesystem access.

Imboard requests keyboard-only control through the XDG Remote Desktop portal.
The desktop permission prompt may describe this portal family as Input Device,
Remote Desktop, or Remote Control. Imboard requests the keyboard capability only.
It does not request screen sharing, pointer control, touchscreen control, remote
login, camera, location, microphone, or network access.

## Stored data

Imboard stores local settings with Qt `QSettings`, including:

- appearance settings
- window size and position
- selected keyboard layout
- custom-key assignments
- session-startup preference
- the portal restore token used to reconnect keyboard access

The config menu can disconnect Imboard and delete its saved keyboard-access
restore token. Your desktop privacy settings may separately keep an inactive
portal permission record.

## Clipboard fallback

Normal ASCII text, keys, and shortcuts are sent through the keyboard portal.

Emoji and other non-ASCII text are experimental and disabled by default. When
enabled, Imboard temporarily writes that text to the clipboard and sends
`Ctrl+V`. This may replace the user's current clipboard contents and may not
work in every application.

## Logging

Imboard must not log typed text contents. Diagnostic logs may record that a text,
key, or shortcut action was requested, but not the actual text payload.
