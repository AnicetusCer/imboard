# Imboard Fedora/Flatpak handover

Date: 2026-07-07

This document is for continuing Imboard development from a new machine/session,
especially a Fedora KDE Wayland VM or workstation. It is intentionally safe to
keep public in the repository.

## Current project state

- Repository: `https://github.com/AnicetusCer/imboard`
- App ID: `io.github.anicetuscer.imboard`
- Current release target: `0.2.1`
- Latest GitHub release: `v0.2.1`
- Supported target: KDE Wayland
- Validated targets: SteamOS Desktop Mode and Fedora KDE Wayland
- Intended package route: Flatpak, preferably Flathub rather than ad-hoc tester
  bundles
- Current `main` and tag `v0.2.1` have been pushed.
- The GitHub release `IMBOARD 0.2.1` has been published with the
  `imboard-0.2.1-x86_64.flatpak` bundle.

Imboard is a virtual keyboard for KDE Wayland desktops. It is intended to help
users who need regular desktop/developer keys on compact on-screen keyboards:
symbols, arrows, function keys, lock keys, shortcuts, and configurable custom
keys. The current release has been validated on SteamOS Desktop Mode and Fedora
KDE Wayland. Gamescope/Gaming Mode and non-KDE desktops are outside the current
project scope.

## Important design constraints

- Imboard is a layer-shell client, not a KWin virtual-keyboard plugin.
- Do not add `X-KDE-Wayland-VirtualKeyboard=true`.
- Do not enable KWin virtual-keyboard autoload.
- Input is sent through the XDG Remote Desktop portal with keyboard capability
  only.
- Do not request pointer, touchscreen, screen-cast, camera, location, network,
  or host filesystem access.
- Configurable keys are data only: text, named keys, or validated chords. They
  must not execute shell commands or arbitrary programs.
- Keep the window non-focus-stealing:
  - `Qt.WindowDoesNotAcceptFocus`
  - layer-shell keyboard interactivity set to none

Read these docs before changing behavior:

- `AGENTS.md`
- `docs/architecture.md`
- `docs/code-map.md`
- `docs/release-checklist.md`
- `docs/flatpak-development.md`

## What has already been done

- Full rename/rebrand to Imboard.
- Lowercase app ID: `io.github.anicetuscer.imboard`.
- Old Deckboard/Maliit experiment removed.
- GPL-3.0-or-later license added.
- Trademark/branding note added for the Imboard name.
- Privacy documentation added.
- AppStream metadata added and validated.
- Screenshots copied into `docs/screenshots/`.
- `CHANGELOG.md` added for `0.2.0` and updated for `0.2.1`.
- README polished for public release presentation.
- Flatpak manifest builds locally.
- Flathub submission path documented in `docs/flathub-submission.md`.
- Public-release safety notes documented in `docs/public-release-audit.md`.
- GitHub release `v0.2.1` created and marked latest.
- Security polish pass completed:
  - fallback X11 socket included only for Flathub's native-Wayland packaging
    rule;
  - no network permission;
  - no host filesystem permission;
  - local control socket rejects oversized commands;
  - experimental Unicode attempts to restore previous clipboard text.

## Last known Steam Deck manual test result

The installed Flatpak was tested on SteamOS Desktop Mode:

- Imboard opens.
- Permission flow works both ways across reboots.
- Config wording is clear.
- System tray show/hide works.
- Typing works in Kate and Zed for normal keys/chords/custom keys.
- Emoji input did not work reliably in Kate/Zed and remains experimental.

## Fresh WSL setup

Clone the repo:

```sh
git clone https://github.com/AnicetusCer/imboard.git
cd imboard
```

Recommended packages depend on the WSL distribution. For Ubuntu-like WSL:

```sh
sudo apt update
sudo apt install -y git cmake ninja-build g++ qt6-base-dev qt6-declarative-dev \
    qt6-tools-dev qt6-tools-dev-tools libqt6dbus6 libqt6quick6 appstream \
    flatpak flatpak-builder
```

Layer-shell support may require distro-specific packages or building
`layer-shell-qt`. The Flatpak manifest already builds a pinned layer-shell-qt
dependency, so native WSL builds are mainly for compile/test/doc work.

WSL may not provide a useful Wayland compositor, tray, or desktop portal
environment for runtime testing. Treat WSL as a source-check and packaging-prep
environment, then do runtime validation on Fedora KDE Wayland or SteamOS Desktop
Mode.

## Fedora KDE test system

A Fedora KDE Wayland system is the preferred development and release-prep
environment for build, Flatpak, portal, tray, and general KDE Wayland
validation. SteamOS Desktop Mode remains an important validated environment
because it is one of the original use cases.

Pull the current repo there:

```sh
git clone https://github.com/AnicetusCer/imboard.git
cd imboard
```

Install build and Flatpak tooling:

```sh
sudo dnf update
sudo dnf install -y git cmake ninja-build gcc-c++ qt6-qtbase-devel \
    qt6-qtdeclarative-devel qt6-qttools-devel appstream flatpak \
    flatpak-builder layer-shell-qt-devel ripgrep
flatpak remote-add --if-not-exists flathub \
    https://flathub.org/repo/flathub.flatpakrepo
flatpak install --user flathub org.kde.Sdk//6.10 org.kde.Platform//6.10 \
    org.flatpak.Builder
```

Run source, native, and Flatpak checks:

```sh
git status --short --branch
git diff --check
appstreamcli validate --no-net --pedantic packaging/io.github.anicetuscer.imboard.metainfo.xml
cmake -S . -B build -G Ninja
cmake --build build --target imboard_qmllint
ninja -C build imboard
ctest --test-dir build --output-on-failure
flatpak-builder --user --install --force-clean flatpak-build \
    packaging/io.github.anicetuscer.imboard.yml
```

Run the installed Flatpak in the Fedora KDE Wayland session:

```sh
flatpak run io.github.anicetuscer.imboard --toggle
```

Manual Fedora KDE checks:

1. Confirm the session is KDE Wayland, not X11.
2. Confirm Imboard opens above normal windows and does not take keyboard focus.
3. Click the `IMBOARD` title and confirm the About popup opens; test GitHub,
   Ko-fi, and Privacy links.
4. Complete the portal permission setup and confirm the desktop permission
   wording is understandable.
5. Confirm CONFIG can remove saved keyboard access and then repair it.
6. Confirm system tray show/hide and quit behavior.
7. Confirm `RUN AT LOGIN` uses the Background portal and starts hidden after
   login.
8. Type in at least Konsole, Kate, and one Flatpak app:
   - normal letters;
   - Backspace hold-repeat;
   - symbols;
   - Ctrl/Ctrl+Shift chords;
   - one configured custom key.
9. Treat Gamescope/Gaming Mode as out of scope unless the project goals change.

## Release bundle build path

For a normal Fedora KDE development system, the preferred release-bundle command
is:

```sh
sh ./scripts/build-release-bundle.sh
```

On SteamOS, building inside a Distrobox/container can fail before compiling the
app with a nested Bubblewrap mount error involving `/etc/resolv.conf`:

```text
bwrap: Can't bind mount /oldroot/etc/resolv.conf on /newroot/etc/resolv.conf:
Unable to mount source on destination: No such file or directory
```

This is an environment issue caused by running Flatpak Builder's sandbox inside
another container. It is not an Imboard compile or packaging failure. Prefer a
normal Fedora KDE environment for release builds. If a SteamOS build is needed,
use the installed `org.flatpak.Builder` Flatpak instead of running
`flatpak-builder` inside Distrobox:

```sh
flatpak run --filesystem="$PWD" org.flatpak.Builder \
    --user --force-clean \
    --repo="$PWD/flatpak-repo" \
    "$PWD/flatpak-build" \
    "$PWD/packaging/io.github.anicetuscer.imboard.yml"

flatpak build-bundle \
    --runtime-repo=https://dl.flathub.org/repo/flathub.flatpakrepo \
    "$PWD/flatpak-repo" \
    "$PWD/imboard-0.2.1-x86_64.flatpak" \
    io.github.anicetuscer.imboard
```

The `v0.2.1` release bundle was built successfully with this fallback path.

## Validation commands

Local source checks:

```sh
git status --short --branch
git diff --check
appstreamcli validate --no-net --pedantic packaging/io.github.anicetuscer.imboard.metainfo.xml
```

Native build/test, if the WSL or Fedora Qt setup is complete:

```sh
cmake -S . -B build -G Ninja
cmake --build build --target imboard_qmllint
ninja -C build imboard
ctest --test-dir build --output-on-failure
```

Flatpak build:

```sh
flatpak install --user flathub org.kde.Sdk//6.10 org.kde.Platform//6.10
flatpak-builder --user --force-clean flatpak-build packaging/io.github.anicetuscer.imboard.yml
```

On Fedora KDE, use the Fedora section above for secondary runtime validation.
On SteamOS, use the commands in `docs/release-checklist.md` for final install
and manual runtime validation.

## Flathub direction

The next major workstream should be preparing a Flathub submission.

Likely tasks:

1. Make the GitHub repository public if it is not already public.
   The public-facing history and `v0.2.1` tag have been prepared; see
   `docs/public-release-audit.md`.
2. Confirm the repository, issue tracker, AppStream URLs, and screenshot URLs
   work publicly.
3. Review Flathub manifest expectations:
   - app ID is valid;
   - licenses are correct;
   - screenshots are reachable;
   - no excessive sandbox permissions;
   - release metadata is present.
4. Confirm `v0.2.1` is present and the release asset is reachable before
   submitting.
5. Prepare the Flathub PR from the top-level
   `io.github.anicetuscer.imboard.yml` manifest.
6. Confirm whether Flathub accepts the pinned `layer-shell-qt` build module as
   written or wants a different source reference/release tag.
7. Re-run the full release checklist on SteamOS after any Flathub-review changes.

Do not claim Gamescope/Gaming Mode support in Flathub metadata unless the
project goals change and it has been explicitly tested.

## Known caveats

- SteamOS Desktop Mode and Fedora KDE Wayland have been validated.
- Non-KDE Wayland desktops are outside the supported target scope.
- Gamescope/Gaming Mode is outside the supported target scope.
- Emoji/non-ASCII input is experimental and app-dependent.
- The portal permission dialog may say Input Device, Remote Desktop, or Remote
  Control. Imboard requests keyboard capability only.
- The Remote Desktop portal permission is inherently powerful even when limited
  to keyboard capability, so permission wording must remain clear.

## Suggested next session prompt

Use this to restart work from another machine:

```text
We are continuing Imboard from https://github.com/AnicetusCer/imboard.
Read AGENTS.md and docs/handover-wsl-flathub.md first.
I have a Fedora KDE Wayland test system available.
Goal: pull the current repo, validate the 0.2.1 GitHub release and
Flathub/public-release path, and avoid runtime behavior changes unless required
by packaging review.
```
