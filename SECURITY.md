# Security

IMBOARD sends keyboard events through the user-approved XDG Remote Desktop
portal. It does not request network access, host filesystem access, pointer
control, touchscreen control, screencast, camera, or location access. Offline
dictation uses microphone access only during an explicit, visibly indicated
recording and processes audio locally in memory.

The Flatpak manifest grants:

- Wayland display access
- fallback X11 socket for Flatpak native-Wayland packaging compatibility
- PulseAudio/PipeWire audio access for user-initiated microphone recording
- DRI for Qt graphics
- IPC shared-memory support
- KDE StatusNotifierWatcher DBus access for tray integration
- XDG Remote Desktop portal keyboard capability, requested at runtime

Imboard does not persist recordings or transcripts and does not log their
contents. The optional speech model is a separately installed, read-only
Flatpak extension, so the running keyboard requires no network permission.

Official GitHub release bundles have signed SHA-256 checksums. The dedicated
IMBOARD release-signing public key is stored in
`packaging/imboard-release-signing-public.asc` and has fingerprint:

```text
3E5D 814D 453E CD6C D953 7782 D1DE 8A0E 1D76 C26C
```

Saved portal restore tokens are stored in the application settings file with
owner-only read and write permissions (`0600`). If those permissions cannot be
enforced, Imboard refuses to treat the saved token as reusable.

Microphone capture is limited to 60 seconds and 64 MiB of in-memory audio.
Implausible device formats are rejected before recording begins, and capture
stops with an error if the byte ceiling is exceeded.

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
- release executable hardening: PIE, strong stack protection, Fortify, full
  RELRO, and immediate symbol binding

There is currently no third-party security certificate for IMBOARD. Treat GitHub
release tags, source code, reproducible local builds, the documented Flatpak
permissions, and public issue history as the trust material for the project.
