# Flathub submission path

This tracks the packaging-only path for the `0.1.0` submission. It does
not change Imboard runtime behavior.

## Current gates

- `AnicetusCer/imboard` is currently private. Make it public before submitting,
  because Flathub requires reachable source, metadata, screenshot, and issue
  URLs. Follow `docs/public-release-audit.md` before changing visibility.
- `v0.1.0` is tagged on the clean public-facing release commit. Confirm it is
  reachable after switching the repository public.
- `0.1.0` is scoped to KDE Wayland and SteamOS Desktop Mode. Gamescope/Gaming
  Mode and non-KDE desktops are not supported targets.
- Re-run the SteamOS Desktop Mode release checklist after every packaging
  review change that could affect installation, metadata, permissions, or
  launch behavior.

## Files

- `packaging/io.github.anicetuscer.imboard.yml` remains the local development
  manifest. It uses `type: dir` so it can build the current working tree.
- `io.github.anicetuscer.imboard.yml` is the Flathub submission manifest. It is
  top-level, named after the app ID, and uses public Git sources.
- `packaging/io.github.anicetuscer.imboard.metainfo.xml` is installed from
  upstream and should remain the canonical AppStream metadata.

## Pre-submission checks

The Flathub submission manifest build requires the repository to be public and
the `v0.1.0` tag to exist on GitHub.

From the upstream repo:

```sh
git status --short --branch
git diff --check
appstreamcli validate --no-net --pedantic packaging/io.github.anicetuscer.imboard.metainfo.xml
flatpak-builder --user --force-clean flatpak-build packaging/io.github.anicetuscer.imboard.yml
flatpak-builder --user --force-clean flathub-build io.github.anicetuscer.imboard.yml
```

With `org.flatpak.Builder` installed, also run:

```sh
flatpak run --command=flatpak-builder-lint org.flatpak.Builder appstream packaging/io.github.anicetuscer.imboard.metainfo.xml
flatpak run --command=flatpak-builder-lint org.flatpak.Builder manifest io.github.anicetuscer.imboard.yml
```

For a local Flathub-style build, use Flathub's recommended builder invocation:

```sh
flatpak run org.flatpak.Builder --force-clean --sandbox --user --install \
    --install-deps-from=flathub --ccache \
    --mirror-screenshots-url=https://dl.flathub.org/media/ \
    --repo=repo flathub-build io.github.anicetuscer.imboard.yml
flatpak run --command=flatpak-builder-lint org.flatpak.Builder repo repo
```

## Submission steps

1. Make `https://github.com/AnicetusCer/imboard` public.
2. Confirm these URLs work without authentication:
   - `https://github.com/AnicetusCer/imboard`
   - `https://github.com/AnicetusCer/imboard/issues`
   - every screenshot URL in the AppStream metadata
   - `https://github.com/AnicetusCer/imboard.git`
3. Tag the final release commit:

   ```sh
   git tag -a v0.1.0 -m "Imboard 0.1.0"
   git push origin v0.1.0
   ```

   If reviewers request an immutable source reference, add the tag's commit hash
   to the `imboard` source in `io.github.anicetuscer.imboard.yml`.

4. Fork `flathub/flathub` with all branches, branch from `new-pr`, and add the
   top-level `io.github.anicetuscer.imboard.yml` manifest.
5. Open the PR against Flathub's `new-pr` branch with the title
   `Add io.github.anicetuscer.imboard`.
6. In review, be ready to explain:
   - Imboard is a layer-shell client, not a KWin virtual-keyboard plugin.
   - Imboard is designed and tested for KDE Wayland, especially SteamOS
     Desktop Mode, with Fedora KDE Wayland also validated.
   - The app requests the Remote Desktop portal with keyboard capability only.
   - Static sandbox permissions are limited to Wayland, fallback X11, IPC, DRI,
     and KDE status notifier DBus access.
   - The fallback X11 socket is present for Flathub's native-Wayland packaging
     rule; the supported target remains KDE Wayland.
   - No network, host filesystem, pointer, touchscreen, screencast, camera, or
     location access is requested.
   - Gamescope/Gaming Mode and non-KDE desktops are outside the supported
     target scope.
