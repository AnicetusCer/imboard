#!/usr/bin/env sh
# SPDX-FileCopyrightText: 2026 AnicetusCer
# SPDX-License-Identifier: GPL-3.0-or-later

set -eu

APP_ID="io.github.anicetuscer.imboard"
BUILD_DIR="flatpak-build"
MANIFEST="packaging/${APP_ID}.yml"
FLATHUB_REMOTE="https://dl.flathub.org/repo/flathub.flatpakrepo"

if [ ! -f "$MANIFEST" ]; then
    echo "Run this script from the IMBOARD source directory." >&2
    exit 1
fi

for command_name in flatpak flatpak-builder; do
    if ! command -v "$command_name" >/dev/null 2>&1; then
        echo "Missing required command: $command_name" >&2
        echo "Install Flatpak and flatpak-builder with your distro package manager, then rerun this script." >&2
        exit 1
    fi
done

flatpak remote-add --user --if-not-exists flathub "$FLATHUB_REMOTE"
flatpak install --user --noninteractive flathub org.kde.Sdk//6.10 org.kde.Platform//6.10
flatpak-builder --user --install --force-clean "$BUILD_DIR" "$MANIFEST"

cat <<EOF

IMBOARD is installed for this user.

Launch it with:
  flatpak run ${APP_ID} --toggle

Or open IMBOARD from your KDE app launcher.
EOF
