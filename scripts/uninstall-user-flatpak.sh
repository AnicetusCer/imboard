#!/usr/bin/env sh
# SPDX-FileCopyrightText: 2026 AnicetusCer
# SPDX-License-Identifier: GPL-3.0-or-later

set -eu

APP_ID="io.github.anicetuscer.imboard"
MODEL_ID="${APP_ID}.Model.SmallEn"

if ! command -v flatpak >/dev/null 2>&1; then
    echo "Missing required command: flatpak" >&2
    exit 1
fi

# This is best-effort because the normal case includes IMBOARD not running.
# The uninstall below remains authoritative and reports any actionable failure.
flatpak run "$APP_ID" --quit >/dev/null 2>&1 || true

cat <<EOF
Before uninstalling, open IMBOARD's CONFIG panel and use FORGET ACCESS if you
want to remove the saved keyboard portal permission cleanly.

Continuing with Flatpak uninstall now.
EOF

installed_runtimes="$(flatpak list --user --runtime --columns=application)"
if printf '%s\n' "$installed_runtimes" | grep -Fx "$MODEL_ID" >/dev/null 2>&1; then
    flatpak uninstall --user --noninteractive "$MODEL_ID"
fi
flatpak uninstall --user --delete-data --noninteractive "$APP_ID"

cat <<EOF

IMBOARD has been uninstalled for this user.
EOF
