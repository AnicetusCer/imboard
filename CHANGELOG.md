# Changelog

## 0.4.0 - 2026-07-09

Minor release for custom pad only mode.

### Added

- Added custom pad only mode for running IMBOARD as a compact, configurable
  pad of 1 to 16 custom keys.
- Added configurable custom pad only mode key count and grid layout controls.
- Added save/cancel editing, slot reordering, long-press clearing, and
  temporary editor resizing for the custom pad only workflow.
- Added a README GIF showing custom pad only mode with 1 to 16 visible keys.

### Changed

- Expanded custom key storage from 9 to 16 slots.
- Updated custom pad editing so the main board and custom pad only mode share
  the same custom key assignments.

## 0.3.0 - 2026-07-09

Minor release for public-project polish.

### Fixed

- Removed repeated `DeveloperCustomPage` QML warnings caused by transient null
  controller bindings while the custom-key picker is created.

### Changed

- Refreshed the README introduction and install guidance to better explain
  IMBOARD's purpose, portal-based input path, and GitHub-release distribution.

## 0.2.2 - 2026-07-07

Patch release for QML lint cleanup and release polish.

### Fixed

- Restored visible developer-pad keys after extracting page components for
  cleaner QML scoping.
- Removed remaining QML lint and Qt policy warnings from the Fedora build path.

### Changed

- Added the app version to the About popup footer.

## 0.2.1 - 2026-07-07

Patch release for startup and native-build polish.

### Fixed

- Removed repeated QML startup warnings caused by `DeveloperPad` bound component
  instantiation through page loaders.
- Disabled Qt QML import scanning for the app module to avoid Qt 6.4 native
  build hangs in the Steam Deck development environment.
- Adjusted main-board modifier helper code so QML lint passes cleanly with the
  Qt 6.4 toolchain.

## 0.2.0 - 2026-07-06

Initial release for KDE Wayland.

### Added

- Transparent, movable, resizable Wayland keyboard surface for KDE Desktop Mode.
- Main alphabet keyboard with US and GB layout choices.
- Physical-key-style Shift and Caps behavior for layout-matched typing.
- Long-press Shift lock for selection with arrows and navigation keys.
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

- Tested on SteamOS Desktop Mode and Fedora KDE Wayland.
- Gamescope/Gaming Mode support is not targeted.
- Emoji and non-ASCII input are experimental and may not work in every app.
- Non-KDE Wayland desktops are not supported targets.
