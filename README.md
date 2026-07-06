# Imboard

Imboard, short for Input Method Board, is a Steam Deck-first virtual keyboard
for KDE Wayland Desktop Mode. It combines a permanent alphabet board with a
swipeable developer pad for numbers, symbols, navigation, function keys,
shortcuts, and user-defined key actions.

Imboard exists because desktop work on the Steam Deck often needs keys that are
awkward to access consistently on compact on-screen keyboards: pipes, braces,
arrows, function keys, lock keys, and application shortcuts. The built-in Steam
keyboard is useful for normal text entry; Imboard is aimed at scripting,
editing, terminal work, and other developer-heavy desktop tasks.

## Status

Current release target: `0.2.0`.

Imboard presents required keyboard-access setup on first visible launch. The
standard desktop portal grants keyboard-only control and returns a restore token
for later sessions. Imboard remains input-inert until that setup succeeds.
KWin virtual-keyboard registration remains excluded from normal build and
install paths because Imboard uses layer-shell and desktop portals instead.

SteamOS Desktop Mode on KDE Wayland is the primary target. Fedora KDE Wayland is
also validated as a current KDE desktop environment. Other KDE Wayland desktops
may work if they support layer-shell and the XDG Remote Desktop portal.

## Screenshots

![Imboard with function-key developer pad](docs/screenshots/imboard-main-fkeys.png)

![Imboard custom-key pad on the left](docs/screenshots/imboard-custom-pad.png)

![Imboard appearance settings](docs/screenshots/imboard-appearance-settings.png)

![Imboard transparent overlay while typing in an editor](docs/screenshots/imboard-transparent-overlay.png)

## Product constraints

- Native Wayland and designed for the Steam Deck's 1280x800 display.
- One compositor-managed transparent surface containing two visual panels.
- A fixed alphabet board and a horizontally swipeable developer pad.
- Configurable actions are data, not shell commands.
- SteamOS Desktop Mode and KDE Wayland are the supported target environment.
- Gamescope/Gaming Mode and non-KDE desktops are outside the current project
  scope.

## Developer pad pages

1. Numeric keypad and navigation
2. Common scripting characters
3. Extended characters
4. Function keys
5. Common chords
6. User-assigned text, keys, or chords

## Build

Imboard requires CMake 3.21+, Qt 6.4+ with Qt Quick and Qt DBus, and Ninja.

```sh
cmake -S . -B build -G Ninja
cmake --build build
ctest --test-dir build
```

Run a development build with:

```sh
timeout --signal=TERM --kill-after=2s 10m ./build/imboard
```

Keys log their requested actions until initial keyboard-access setup succeeds.
After setup, later launches automatically attempt to restore the saved portal
session; CONFIG exposes READY or REPAIR status rather than an input off switch.

Only one Imboard instance can run. A second launch asks the existing window to
show instead of creating another process. A reliable external shutdown path is:

```sh
./build/imboard --quit
```

Emoji tooltip artwork is from [Twemoji](https://github.com/twitter/twemoji),
used unmodified under CC BY 4.0. The bundled graphics licence is at
`assets/twemoji/LICENSE-GRAPHICS`. Emoji and other non-ASCII text input are
experimental and disabled by default because the current fallback temporarily
uses the clipboard before sending `Ctrl+V`, then attempts to restore the
previous clipboard text.

Regional main-keyboard layouts are JSON resources. Imboard includes common
English QWERTY regional choices and behaves like a physical keyboard: choose the
layout that matches the current KDE or SteamOS system keyboard layout. See
[Adding keyboard layouts](docs/keyboard-layouts.md) for the extension schema.

The local Flatpak development manifest and test procedure are described in
[Flatpak development build](docs/flatpak-development.md).

Flathub submission preparation is tracked in
[Flathub submission path](docs/flathub-submission.md).

Release validation is tracked in [Release checklist](docs/release-checklist.md).

Contributor and AI-maintainer guidance starts in [AGENTS.md](AGENTS.md). The
current component ownership and runtime flow are documented in
[Code map](docs/code-map.md).

## Known limitations

- Gamescope/Gaming Mode support is not targeted.
- Emoji and non-ASCII text input are experimental and app-dependent.
- The keyboard uses the XDG Remote Desktop portal because Wayland correctly
  blocks ordinary apps from injecting input into other apps without permission.
- Portal permission wording varies by desktop and may mention Input Device,
  Remote Desktop, or Remote Control even though Imboard requests keyboard
  capability only.
- The selected Imboard layout must match the desktop keyboard layout for shifted
  symbols to match the key labels.
- Non-KDE Wayland desktops are not supported targets. Imboard shows a one-time
  compatibility note if launched outside KDE.

## Maintenance and support

Imboard is a spare-time project. Bug reports, focused pull requests, and SteamOS
Desktop Mode test results are welcome. If Imboard saves you time and you want to
support the work, Ko-fi donations are welcome at
<https://ko-fi.com/anicetuscer>.

## Licence and branding

Imboard is free software licensed under GPL-3.0-or-later; see [LICENSE](LICENSE).

The Imboard name and official branding identify the upstream project. Modified
redistributions must not imply that they are official Imboard releases unless
that use has been approved. See [Imboard name and branding](TRADEMARKS.md).

## Roadmap

- [x] Safe movable/resizable window lifecycle harness
- [x] Nine-key programmable bank with transactional Set mode
- [x] Swipeable developer pad with numeric, code, F-key and combo pages
- [x] Add touch-friendly custom-key picker categories
- [x] Add persistent regional keyboard layout selection
- [ ] Refine custom-key picker touch feedback
- [x] Text and single-key injection through the keyboard-only portal session
- [x] Press/release modifier state and chords
- [x] Manual system-tray show/hide control
- [x] Editable user page with validated persistent configuration writes
- [x] Flatpak-compatible run-at-login through the Background portal
- [x] Flatpak packaging and SteamOS integration tests
- [x] Fedora KDE Wayland validation

## Safety

Do not add `X-KDE-Wayland-VirtualKeyboard=true` to an Imboard desktop entry or
enable KWin virtual-keyboard autoload. Imboard is a layer-shell client and uses
the desktop portal for input; it is not a KWin input-method plugin.
