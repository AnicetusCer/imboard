# Imboard release checklist

Use this checklist before tagging or publishing an Imboard build.

## Source checks

```sh
git status --short --branch
git diff --check
appstreamcli validate --no-net --pedantic packaging/io.github.anicetuscer.imboard.metainfo.xml
```

The working tree should be clean before tagging. AppStream validation uses
`--no-net` for local checks; run without it only after the public project URLs
are live.

For Flathub submission preparation, also follow
`docs/flathub-submission.md`.

Before making the repository public, also follow
`docs/public-release-audit.md`.

## Build and automated tests

In the SteamOS development distrobox:

```sh
distrobox enter deckst-dev -- cmake -S /home/deck/imboard -B /home/deck/imboard/build -G Ninja
distrobox enter deckst-dev -- cmake --build /home/deck/imboard/build --target imboard_qmllint
distrobox enter deckst-dev -- ninja -C /home/deck/imboard/build imboard
distrobox enter deckst-dev -- ctest --test-dir /home/deck/imboard/build --output-on-failure
```

Expected result:

- QML lint exits successfully. The current Qt toolchain may print informational
  `contentItem` deferred-assignment messages.
- All CTest tests pass.

## Flatpak build and install

Build from the distrobox:

```sh
distrobox enter deckst-dev -- flatpak-builder --user --install --force-clean /home/deck/imboard/flatpak-build /home/deck/imboard/packaging/io.github.anicetuscer.imboard.yml
```

If installation fails inside distrobox with a session-bus connection error,
install the exported build from the host:

```sh
flatpak install --user --reinstall --noninteractive /home/deck/imboard/.flatpak-builder/cache io.github.anicetuscer.imboard
flatpak run io.github.anicetuscer.imboard --toggle
```

Confirm the installed app ID:

```sh
flatpak list --user --app --columns=application | rg 'imboard|Imboard|Deckboard'
```

Only `io.github.anicetuscer.imboard` should appear for Imboard.

## Manual SteamOS test pass

Test on the Steam Deck desktop session:

1. Launch Imboard from Utilities or `flatpak run io.github.anicetuscer.imboard --toggle`.
2. Confirm the keyboard opens and remains above normal windows.
3. Complete the permission setup flow:
   - explanation text is clear;
   - system permission is requested through the portal;
   - permission restore works after reboot.
4. Confirm the config menu:
   - `KEYBOARD INPUT` reports ready/remove state correctly;
   - `RUN AT LOGIN` wording is present;
   - no taskbar/session wording remains in user-facing controls.
5. Confirm run-at-login behavior:
   - enabling it starts Imboard hidden in the system tray after login;
   - disabling it leaves Imboard manual-launch only.
6. Confirm tray behavior:
   - minimise hides the keyboard;
   - tray icon shows and hides the keyboard;
   - tray quit exits the process.
7. Confirm typing in at least Kate and Zed:
   - normal letters;
   - Backspace hold-repeat;
   - common symbols;
   - at least one chord such as Ctrl+C or Ctrl+V;
   - at least one configured custom key.

## Known release caveats

- Emoji and non-ASCII text input are experimental. They use the clipboard and
  `Ctrl+V`, then attempt to restore the previous clipboard text. They may fail
  or behave differently by target app.
- The portal permission dialog may describe the request as Input Device, Remote
  Desktop, or Remote Control depending on desktop implementation. Imboard
  requests only keyboard capability.
- Gamescope/Gaming Mode is outside the supported target scope.
- Non-KDE Wayland desktops are outside the supported target scope and receive a
  one-time compatibility note.
