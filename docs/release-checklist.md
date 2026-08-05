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

The repository-root Flatpak manifest builds the tagged release rather than the
working tree. When preparing a new tag, update its `imboard` source tag and
confirm that the tagged model path matches the model-extension mount path.

For Flathub submission preparation, also follow
`docs/flathub-submission.md`.

Before making the repository public, also follow
`docs/public-release-audit.md`.

## Release signing

Official GitHub release bundles and their checksum file are signed by the
dedicated IMBOARD release key:

```text
3E5D 814D 453E CD6C D953 7782 D1DE 8A0E 1D76 C26C
```

The canonical fingerprint without spaces is:

```text
3E5D814D453ECD6CD9537782D1DE8A0E1D76C26C
```

The public key is stored at
`packaging/imboard-release-signing-public.asc`. The private key must remain in
the dedicated `~/.gnupg-imboard` keyring and in the maintainer's encrypted
backup. Never copy a private key, passphrase, or revocation certificate into
the repository.

Build release artifacts from the repository root with:

```sh
sh ./scripts/build-release-bundle.sh
```

The script refuses to build release artifacts when the dedicated private key
is unavailable. It signs both Flatpak repository commits and produces a signed
SHA-256 checksum file for the downloadable bundles.

Upload all four generated artifacts plus
`packaging/imboard-release-signing-public.asc` to the GitHub release. Do not
upload any file from `~/imboard-gpg-backup`.

Before uploading a release, verify its signature and checksums using a clean
temporary keyring:

```sh
verification_home="$(mktemp -d)"
chmod 700 "$verification_home"
gpg --homedir "$verification_home" --import packaging/imboard-release-signing-public.asc
gpg --homedir "$verification_home" --verify imboard-*-SHA256SUMS.asc imboard-*-SHA256SUMS
sha256sum --check imboard-*-SHA256SUMS
```

Confirm that GPG reports the fingerprint above, then remove the temporary
verification directory.

## Build and automated tests

In the SteamOS development distrobox:

```sh
distrobox enter deckst-dev -- cmake -S /home/deck/github/imboard -B /home/deck/github/imboard/build -G Ninja
distrobox enter deckst-dev -- cmake --build /home/deck/github/imboard/build --target imboard_qmllint
distrobox enter deckst-dev -- ninja -C /home/deck/github/imboard/build imboard
distrobox enter deckst-dev -- ctest --test-dir /home/deck/github/imboard/build --output-on-failure
```

Expected result:

- QML lint exits successfully. The current Qt toolchain may print informational
  `contentItem` deferred-assignment messages.
- All CTest tests pass.

## Flatpak build and install

Build from the distrobox:

```sh
distrobox enter deckst-dev -- flatpak-builder --user --install --force-clean /home/deck/github/imboard/flatpak-build /home/deck/github/imboard/packaging/io.github.anicetuscer.imboard.yml
```

If installation fails inside distrobox with a session-bus connection error,
install the exported build from the host:

```sh
flatpak install --user --reinstall --noninteractive /home/deck/github/imboard/.flatpak-builder/cache io.github.anicetuscer.imboard
flatpak run io.github.anicetuscer.imboard --toggle
```

Build and install the optional model extension separately:

```sh
distrobox enter deckst-dev -- flatpak-builder --user --install --force-clean /home/deck/github/imboard/flatpak-model-build /home/deck/github/imboard/packaging/io.github.anicetuscer.imboard.Model.SmallEn.yml
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
7. Enter Gaming Mode, return to Desktop Mode, and confirm Imboard starts or
   toggles normally without manual runtime-file cleanup. Confirm keyboard input
   reconnects without reaching `REPAIR`; if the compositor requires another
   permission confirmation, confirm Imboard hides so the dialog remains visible.
8. Confirm typing in at least Kate and Zed:
   - normal letters;
   - Backspace hold-repeat;
   - common symbols;
   - at least one chord such as Ctrl+C or Ctrl+V;
   - at least one configured custom key.
9. Confirm offline transcription:
   - without the model extension, the header shows `ADD SPEECH` and opens the
     add-on installation guidance;
   - after installing the model extension and restarting Imboard, the header
     shows `TRANSCRIBE`;
   - five consecutive record, transcribe, edit, and apply cycles complete;
   - recording stops automatically at 60 seconds;
   - a long transcript wraps and scrolls without clipped text;
   - cancel discards the transcript without applying it;
   - silence or an unavailable microphone reports an error and leaves the
     feature ready to try again;
   - ordinary transcribed text applies correctly in both Kate and Zed;
   - transcription still works after returning from Gaming Mode and after a
     reboot.

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
