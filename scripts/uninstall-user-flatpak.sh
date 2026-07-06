#!/usr/bin/env sh
# SPDX-FileCopyrightText: 2026 AnicetusCer
# SPDX-License-Identifier: GPL-3.0-or-later

set -eu

APP_ID="io.github.anicetuscer.imboard"

if ! command -v flatpak >/dev/null 2>&1; then
    echo "Missing required command: flatpak" >&2
    exit 1
fi

flatpak run "$APP_ID" --quit >/dev/null 2>&1 || true

cat <<EOF
Before uninstalling, open IMBOARD's CONFIG panel and use FORGET ACCESS if you
want to remove the saved keyboard portal permission cleanly.

Continuing with Flatpak uninstall now.
EOF

flatpak uninstall --user --delete-data --noninteractive "$APP_ID"

cat <<EOF

IMBOARD has been uninstalled for this user.
EOF
