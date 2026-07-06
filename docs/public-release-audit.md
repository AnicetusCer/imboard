# Public release audit

This records the final checks for publishing `AnicetusCer/imboard`.

## Current state

- Public-facing history has been reduced to one initial release commit.
- The `v0.2.0` tag points at the current release commit.
- Commit author, committer, and tagger use:
  `AnicetusCer <dev.acer.certified955@passmail.net>`.
- Generated build directories are not tracked.

## Checks run

- Listed tracked files with `git ls-files`.
- Searched the tracked tree, excluding generated build directories, for common
  private-key, token, OAuth, password, API-key, email, and local-user-path
  patterns.
- Checked Flatpak finish arguments for excessive sandbox permissions and
  Flathub linter compatibility.
- Confirmed AppStream metadata validates with `--no-net --pedantic`.
- Confirmed native build, QML lint, CTest, and local Flatpak build/install pass
  from the clean-history tree.

## Findings

- No real secrets or credentials were found.
- Token hits are portal restore-token documentation, generated portal handle
  tokens, coding-symbol categories, and test sentinel strings.
- The only public email address is the intended development alias.
- Flatpak permissions are limited to Wayland, fallback X11, IPC, DRI, and KDE
  status notifier DBus access. The fallback X11 socket is included for
  Flathub's native-Wayland packaging rule; the supported target remains KDE
  Wayland. The app does not request network, broad X11, host filesystem,
  pointer, touchscreen, screencast, camera, or location access.

## Before switching public

Re-run the lightweight checks:

```sh
git status --short --branch
git diff --check
appstreamcli validate --no-net --pedantic packaging/io.github.anicetuscer.imboard.metainfo.xml
```

After switching public, confirm the repository, issue tracker, tag, and
AppStream screenshot URLs are reachable without authentication.
