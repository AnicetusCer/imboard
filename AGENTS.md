# Imboard maintenance guide

This file is the entry point for AI-assisted changes. Read
`docs/architecture.md` and `docs/code-map.md` before changing behavior. For
release or packaging work, also read `docs/release-checklist.md` and
`docs/flathub-submission.md`.

## Required invariants

- Imboard is a layer-shell client, not a KWin input-method plugin. Never add
  `X-KDE-Wayland-VirtualKeyboard=true` or enable KWin virtual-keyboard autoload.
- The keyboard surface must remain above normal windows without taking keyboard
  focus. Keep `Qt.WindowDoesNotAcceptFocus` and layer-shell
  `KeyboardInteractivityNone` intact.
- Portal input requests keyboard capability only. Do not request pointer,
  touchscreen, screen-cast, camera, location, or network access.
- Supported runtime targets are KDE Wayland desktop sessions, especially
  SteamOS Desktop Mode. Do not claim Gamescope/Gaming Mode or non-KDE desktop
  support without a deliberate project-scope change and matching tests.
- Every injected key press must have a matching release. Chord modifiers are
  released in reverse order. Preserve the failed-release safety path in
  `PortalInputBackend`.
- External failures must not be silently converted to success. Input and
  permission failures close the portal session; persistence failures remain
  visible through status/error properties or an explicit warning for
  non-critical appearance and geometry settings.
- An intentionally ignored cleanup result needs a comment explaining why no
  recovery is possible. Do not discard return values from writes, IPC, portal
  calls, or window-system requests.
- User-defined actions may contain text, named keys, or modifier chords. They
  must never execute shell commands or arbitrary processes.
- QML objects named in `SmokeTestController` are test API. Rename one only when
  updating the smoke test in the same change.
- Preserve existing `QSettings` keys unless the change includes a migration.

## Repository map

- `src/`: C++ lifecycle, persistence, portal, and surface controllers.
- `qml/Main.qml`: composition only; keep feature UI in focused components.
- `qml/KeyboardSurface.qml`: frame, movement, resize, and board placement.
- `qml/*Popup.qml`: one settings or permission workflow per component.
- `qml/DeveloperPad.qml`: developer pages, catalog, and custom-key editor.
- `layouts/`: read-only regional alphabet-board data.
- `tests/`: unit, lifecycle, and QML smoke tests.
- `packaging/`: desktop entry, icon, and Flatpak manifest.

Generated directories (`build*`, `.flatpak-builder`, `flatpak-build`,
`flatpak-repo`) are not source. Do not edit or search them for implementation
references.

## Build and test

On a machine with the documented dependencies installed:

```sh
cmake -S . -B build -G Ninja
cmake --build build
cmake --build build --target imboard_qmllint
ctest --test-dir build --output-on-failure
```

Steam Deck distrobox and Fedora KDE setup details live in
`docs/release-checklist.md` and `docs/handover-wsl-flathub.md`.

Run the QML linter and full test suite after changes to C++, QML, CMake,
layouts, or packaging. The QML smoke test is mandatory after moving components
or changing popup geometry. Portal tests do not grant real desktop permission.

## Change discipline

- Prefer explicit component properties and signals over access to unrelated
  parent IDs.
- Keep bootstrap and object wiring in `main.cpp`; put test choreography in
  `SmokeTestController` and behavior in the owning controller.
- Add persistence validation tests for new stored values.
- Add a failure-path test when introducing a new filesystem, IPC, or portal
  boundary.
- Add new layouts as JSON and follow `docs/keyboard-layouts.md`.
- Check `git diff --check` and review the full diff before committing.
