# Changelog

## 0.1.0 - 2026-07-06

Initial release for SteamOS Desktop Mode and KDE Wayland.

### Added

- Transparent, movable, resizable Wayland keyboard surface for KDE Desktop Mode.
- Main alphabet keyboard with US and GB layout choices.
- Swipeable developer pad pages for:
  - numbers and navigation;
  - scripting symbols;
  - extended symbols;
  - function keys and lock keys;
  - common keyboard chords;
  - nine user-configurable custom keys.
- System tray show/hide control.
- Optional run-at-login behavior that starts Imboard hidden in the system tray.
- Keyboard-only input through the XDG Remote Desktop portal.
- First-run permission explanation and removal flow.
- Appearance presets, opacity control, and optional border visibility.
- Experimental emoji/non-ASCII input option.
- One-time compatibility note when launched outside KDE.
- Flatpak development manifest.

### Security and privacy

- Imboard requests keyboard capability through the portal and does not request
  screen sharing, pointer control, host filesystem access, or network access.
- Configurable actions are stored as text, named keys, or validated chords; they
  cannot execute shell commands.
- Experimental Unicode input briefly uses the clipboard and then attempts to
  restore the previous clipboard text.

### Known limitations

- SteamOS Desktop Mode on KDE Wayland is the primary tested target.
- Fedora KDE Wayland has also been validated.
- Gamescope/Gaming Mode support is not targeted.
- Emoji and non-ASCII input are experimental and may not work in every app.
- Non-KDE Wayland desktops are not supported targets.
