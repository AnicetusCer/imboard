# Imboard documentation map

<!-- SPDX-FileCopyrightText: 2026 AnicetusCer -->
<!-- SPDX-License-Identifier: GPL-3.0-or-later -->

Use this page to decide which project document is authoritative. Historical
notes are useful context, but they must not override current source or the
documents listed below.

## Authoritative documents

- `../AGENTS.md`: invariants, repository boundaries, and required checks.
- `architecture.md`: runtime design and security-sensitive behavior.
- `code-map.md`: file ownership, persistent settings, and change-to-test map.
- `release-checklist.md`: current release validation and manual test procedure.
- `flatpak-development.md`: current local Flatpak build and installation flow.
- `steam-deck-handover.md`: current Fedora-to-Steam-Deck transfer and physical
  transcription test procedure.
- `../README.md`: supported user-facing features and installation instructions.

When these documents disagree, treat `AGENTS.md` and the current implementation
as authoritative and repair the stale document in the same change.

## Historical documents

- `handover-wsl-flathub.md`: dated environment handover notes retained for
  background only.
- `public-release-audit.md`: snapshot of a completed public-release audit.

Historical documents may name old releases, completed tasks, or superseded
distribution plans. Do not use them to infer current behavior.
