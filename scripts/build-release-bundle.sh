#!/usr/bin/env sh
# SPDX-FileCopyrightText: 2026 AnicetusCer
# SPDX-License-Identifier: GPL-3.0-or-later

set -eu

APP_ID="io.github.anicetuscer.imboard"
VERSION="0.2.2"
ARCH="$(flatpak --default-arch)"
BUILD_DIR="flatpak-build"
REPO_DIR="flatpak-repo"
BUNDLE="imboard-${VERSION}-${ARCH}.flatpak"
MANIFEST="packaging/${APP_ID}.yml"
RUNTIME_REPO="https://dl.flathub.org/repo/flathub.flatpakrepo"

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

flatpak remote-add --user --if-not-exists flathub "$RUNTIME_REPO"
flatpak install --user --noninteractive flathub org.kde.Sdk//6.10 org.kde.Platform//6.10
flatpak-builder --user --force-clean --repo="$REPO_DIR" "$BUILD_DIR" "$MANIFEST"
flatpak build-bundle --runtime-repo="$RUNTIME_REPO" "$REPO_DIR" "$BUNDLE" "$APP_ID"

cat <<EOF

Release bundle created:
  ${BUNDLE}

Test install with:
  flatpak install --user ./${BUNDLE}
EOF
