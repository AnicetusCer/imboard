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

for command_name in flatpak; do
    if ! command -v "$command_name" >/dev/null 2>&1; then
        echo "Missing required command: $command_name" >&2
        echo "Install Flatpak and flatpak-builder with your distro package manager, then rerun this script." >&2
        exit 1
    fi
done
if command -v flatpak-builder >/dev/null 2>&1; then
    run_flatpak_builder() {
        flatpak-builder "$@"
    }
elif flatpak info --user org.flatpak.Builder >/dev/null 2>&1 \
    || flatpak info org.flatpak.Builder >/dev/null 2>&1; then
    run_flatpak_builder() {
        flatpak run --filesystem="$(pwd)" org.flatpak.Builder "$@"
    }
else
    echo "Missing required command: flatpak-builder" >&2
    echo "Install flatpak-builder or the org.flatpak.Builder Flatpak, then rerun this script." >&2
    exit 1
fi

flatpak remote-add --user --if-not-exists flathub "$FLATHUB_REMOTE"
flatpak install --user --noninteractive flathub org.kde.Sdk//6.10 org.kde.Platform//6.10
run_flatpak_builder --user --install --force-clean "$BUILD_DIR" "$MANIFEST"

cat <<EOF

IMBOARD is installed for this user.

Offline transcription is an optional add-on. Install the current small.en
model from this source checkout with:
  sh ./scripts/install-user-speech-model.sh

Launch it with:
  flatpak run ${APP_ID} --toggle

Or open IMBOARD from your KDE app launcher.
EOF
