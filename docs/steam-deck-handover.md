# Steam Deck development handover

<!-- SPDX-FileCopyrightText: 2026 AnicetusCer -->
<!-- SPDX-License-Identifier: GPL-3.0-or-later -->

Date: 2026-08-05

This checklist moves current IMBOARD development from the Fedora VM back to a
Steam Deck in KDE Desktop Mode. It covers source transfer, the dedicated
release-signing key, the lightweight Flatpak, and physical microphone testing.

## Scope of the transcription test

IMBOARD intentionally supports one speech model: Whisper `small.en`. It is the
model already found to work well and is distributed as the optional
`io.github.anicetuscer.imboard.Model.SmallEn` Flatpak extension.

There are two supported installation states to test:

1. Lightweight IMBOARD without a model: keyboard features work and the header
   offers `ADD SPEECH`.
2. IMBOARD with the `small.en` extension: the header offers `TRANSCRIBE` and
   transcription runs locally.

There are no medium or large model packages or model selector. Adding those
would be a new product and packaging decision, not part of this handover.

## Before leaving the Fedora VM

The Steam Deck can pull this work only after the VM changes have been reviewed,
committed, and pushed on `feature/transcription-release-hardening`. Confirm a
clean pushed branch before switching machines:

```sh
cd /home/anicetuscer/github/imboard
git status --short --branch
git log -1 --oneline --decorate
```

Do not copy any private key, passphrase, or revocation certificate into the
repository. The repository contains only
`packaging/imboard-release-signing-public.asc`.

## Pull the source on Steam Deck

Open a terminal in KDE Desktop Mode:

```sh
cd /home/deck/imboard
git status --short --branch
git fetch origin
git switch --track origin/feature/transcription-release-hardening
git log -1 --oneline --decorate
```

If the branch already exists locally on the Deck, use this instead:

```sh
git switch feature/transcription-release-hardening
git pull --ff-only
```

If `git status` reports Deck-only changes, stop and preserve them before
switching or pulling. Do not reset or overwrite them merely to complete the
handover. Keep `main` unchanged until the Steam Deck test pass succeeds.

Read the current project guidance before editing:

```sh
sed -n '1,240p' AGENTS.md
sed -n '1,180p' docs/release-checklist.md
sed -n '1,180p' docs/flatpak-development.md
```

## Restore the same release-signing key

Do not generate another key on the Steam Deck. A new key would have a different
fingerprint and break continuity with the public key already committed for
IMBOARD releases.

From Proton Pass, download the encrypted private-key attachment named
`imboard-release-signing-private.asc` into the Deck's Downloads directory. Keep
the passphrase in Proton Pass; do not save it in a shell script or repository.

Create the isolated keyring and import the encrypted key:

```sh
install -d -m 700 /home/deck/.gnupg-imboard
gpg --homedir /home/deck/.gnupg-imboard \
    --import /home/deck/Downloads/imboard-release-signing-private.asc
gpg --homedir /home/deck/.gnupg-imboard \
    --list-secret-keys --keyid-format LONG
```

Confirm the full fingerprint is exactly:

```text
3E5D 814D 453E CD6C D953 7782 D1DE 8A0E 1D76 C26C
```

Also compare the imported key with the repository public key:

```sh
gpg --show-keys --with-fingerprint \
    packaging/imboard-release-signing-public.asc
```

After confirming the private key is present and protected by the expected
passphrase, delete only the downloaded export from `Downloads`. Keep
`/home/deck/.gnupg-imboard`; it is the Deck's working release keyring. Proton
Pass remains the recovery backup.

The release script automatically uses `/home/deck/.gnupg-imboard`. It will open
a local GPG passphrase prompt when a release is signed. Never pass the
passphrase as a command-line argument.

## Validate the source build

Use the existing SteamOS development distrobox:

```sh
distrobox enter deckst-dev -- cmake -S /home/deck/imboard -B /home/deck/imboard/build -G Ninja -DCMAKE_BUILD_TYPE=RelWithDebInfo
distrobox enter deckst-dev -- cmake --build /home/deck/imboard/build --target imboard_qmllint
distrobox enter deckst-dev -- cmake --build /home/deck/imboard/build -j2
distrobox enter deckst-dev -- ctest --test-dir /home/deck/imboard/build --output-on-failure
```

Expected result: QML lint succeeds, the application builds, and all 11 tests
pass.

## Test the lightweight installation without speech

Stop IMBOARD and remove only the optional model if it is already installed:

```sh
flatpak run io.github.anicetuscer.imboard --quit || true
flatpak uninstall --user --noninteractive \
    io.github.anicetuscer.imboard.Model.SmallEn || true
```

Build and install the lightweight application from the checkout:

```sh
cd /home/deck/imboard
sh ./scripts/install-user-flatpak.sh
flatpak run io.github.anicetuscer.imboard --toggle
```

Confirm:

- The keyboard starts and types normally.
- `ADD SPEECH` is shown instead of `TRANSCRIBE`.
- `ADD SPEECH` opens the model installation instructions.
- The application does not attempt a network download.
- CONFIG reports that the speech add-on is not installed.

## Install and test `small.en`

Stop IMBOARD, install the optional model, and restart so Flatpak mounts the new
extension:

```sh
flatpak run io.github.anicetuscer.imboard --quit
cd /home/deck/imboard
sh ./scripts/install-user-speech-model.sh
flatpak run io.github.anicetuscer.imboard --toggle
```

Confirm the extension is installed:

```sh
flatpak info --user io.github.anicetuscer.imboard.Model.SmallEn
```

Perform the physical microphone tests in Kate and at least one other target
application:

- Record a normal short sentence; review, edit, and apply it.
- Complete five consecutive record/transcribe/apply cycles.
- Cancel one recording and confirm no text is sent.
- Record silence and confirm a useful error without stale text.
- Record a longer paragraph and confirm wrapping and scrolling remain usable.
- Confirm ordinary keyboard input still works after transcription.
- Confirm failed delivery keeps the transcript available for retry.
- Confirm the visible countdown and automatic 60-second stop.
- Confirm microphone capture stops immediately after recording.
- Reboot once and confirm the model and keyboard portal permission restore.
- Enter Gaming Mode, return to Desktop Mode, and retest in Desktop Mode.

The supported model is English-only `small.en`; test natural English speech,
punctuation, numbers, and the maintainer's normal speaking pace. Accents and
background noise are useful quality observations, but they are not separate
model-size tests.

## Verify protected settings

After portal setup has completed, confirm the settings file is owner-only:

```sh
stat -c '%a %U:%G %n' \
    /home/deck/.var/app/io.github.anicetuscer.imboard/config/AnicetusCer/Imboard.conf
```

Expected mode: `600`.

## Signed release rehearsal

Do this only after the functional test pass because it rebuilds both release
artifacts and requests the dedicated GPG passphrase:

```sh
cd /home/deck/imboard
sh ./scripts/build-release-bundle.sh
```

The script should create the lightweight bundle, model bundle, SHA-256 checksum
file, and detached signature. Verify them using the commands printed by the
script and confirm GPG reports the expected fingerprint.

Do not publish or replace a GitHub release solely as part of this rehearsal.
Release publication remains a separate explicit maintainer action.

## Completion record

Record the following in the release notes or next handover update:

- Git commit tested.
- SteamOS version and KDE version.
- Core bundle installed without model: pass/fail.
- `small.en` extension installation: pass/fail.
- Five-cycle transcription result.
- Portal restore after reboot: pass/fail.
- Desktop Mode return after Gaming Mode: pass/fail.
- Signed release rehearsal: pass/fail.
- Any microphone hardware or recognition-quality observations.

## Steam Deck validation record: 2026-08-05

- Git commit tested: `c7b9eec` (`feature/transcription-release-hardening`).
- SteamOS version: 3.8.16 stable, build `20260716.1`.
- KDE package versions: `plasma-desktop 6.4.3-1`,
  `plasma-workspace 6.4.3-1.4`.
- Core Flatpak installed without model: pass. Header showed `ADD SPEECH`, and
  the add-speech flow opened the local installation guidance.
- `small.en` extension installation: pass. Installed ref
  `io.github.anicetuscer.imboard.Model.SmallEn/x86_64/0.5`.
- Transcription result: pass. Live microphone dictation worked in the target
  application, including after reboot.
- Five-cycle transcription stress result: not separately recorded.
- Portal and model restore after reboot: pass. No manual cleanup or setup was
  needed; transcription worked immediately after reboot.
- Desktop Mode return after Gaming Mode: pass. Gaming Mode to Desktop Mode was
  tested twice and IMBOARD remained usable.
- Protected settings file: pass. `Imboard.conf` mode was `600`.
- Signed release rehearsal: pass. Generated the lightweight bundle, model
  bundle, SHA-256 checksum file, and detached signature; signature verification
  reported the expected release-signing fingerprint and checksum verification
  passed.
- Recognition-quality observation: microphone dictation was good enough to
  enter text directly into the test conversation.
