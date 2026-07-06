# Security

IMBOARD sends keyboard events through the user-approved XDG Remote Desktop
portal. It does not request network access, host filesystem access, pointer
control, touchscreen control, screencast, camera, microphone, or location
access.

The Flatpak manifest grants:

- Wayland display access
- fallback X11 socket for Flatpak native-Wayland packaging compatibility
- DRI for Qt graphics
- IPC shared-memory support
- KDE StatusNotifierWatcher DBus access for tray integration
- XDG Remote Desktop portal keyboard capability, requested at runtime

## Reporting A Security Issue

Please email `dev.acer.certified955@passmail.net` with a clear description,
the affected version or commit, and steps to reproduce where possible.

This is a one-person project, so replies may not be instant, but keyboard
permission, sandbox escapes, and data-loss issues will be treated as priority
bugs.

## Validation

Before public release, IMBOARD has been checked with:

- native CMake/Ninja build
- Qt QML lint
- CTest unit and smoke tests
- AppStream validation
- REUSE/SPDX licence lint
- Flatpak manifest lint
- Flatpak sandbox build
- Flatpak repo lint

There is currently no third-party security certificate for IMBOARD. Treat GitHub
release tags, source code, reproducible local builds, the documented Flatpak
permissions, and public issue history as the trust material for the project.
