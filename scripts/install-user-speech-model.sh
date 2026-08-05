#!/usr/bin/env sh
# SPDX-FileCopyrightText: 2026 AnicetusCer
# SPDX-License-Identifier: GPL-3.0-or-later

set -eu

APP_ID="io.github.anicetuscer.imboard"
MODEL_ID="${APP_ID}.Model.SmallEn"
BUILD_DIR="flatpak-model-build"
MANIFEST="packaging/${MODEL_ID}.yml"

if [ ! -f "$MANIFEST" ]; then
    echo "Run this script from the IMBOARD source directory." >&2
    exit 1
fi

for command_name in flatpak flatpak-builder; do
    if ! command -v "$command_name" >/dev/null 2>&1; then
        echo "Missing required command: $command_name" >&2
        exit 1
    fi
done

if ! flatpak info --user "$APP_ID" >/dev/null 2>&1; then
    echo "Install IMBOARD first with: sh ./scripts/install-user-flatpak.sh" >&2
    exit 1
fi

flatpak-builder --user --install --force-clean "$BUILD_DIR" "$MANIFEST"

cat <<EOF

The optional Whisper small.en model is installed for this user.

Restart IMBOARD before using offline transcription so Flatpak can mount the
new model add-on.
EOF
