#!/usr/bin/env sh
# SPDX-FileCopyrightText: 2026 AnicetusCer
# SPDX-License-Identifier: GPL-3.0-or-later

set -eu

APP_ID="io.github.anicetuscer.imboard"
MODEL_ID="${APP_ID}.Model.SmallEn"
SIGNING_KEY="3E5D814D453ECD6CD9537782D1DE8A0E1D76C26C"
SIGNING_HOME="${IMBOARD_GPG_HOME:-${HOME}/.gnupg-imboard}"
BUILD_DIR="flatpak-build"
MODEL_BUILD_DIR="flatpak-model-build"
REPO_DIR="flatpak-repo"
MANIFEST="packaging/${APP_ID}.yml"
MODEL_MANIFEST="packaging/${MODEL_ID}.yml"
PUBLIC_KEY="packaging/imboard-release-signing-public.asc"
RUNTIME_REPO="https://dl.flathub.org/repo/flathub.flatpakrepo"

if [ ! -f CMakeLists.txt ] || [ ! -f "$MANIFEST" ] \
    || [ ! -f "$MODEL_MANIFEST" ] || [ ! -f "$PUBLIC_KEY" ]; then
    echo "Run this script from the IMBOARD source directory." >&2
    exit 1
fi

VERSION="$(sed -n 's/^[[:space:]]*project(imboard VERSION \([^[:space:]]*\).*/\1/p' CMakeLists.txt)"
MODEL_BRANCH="$(sed -n 's/^[[:space:]]*branch:[[:space:]]*"\([^"]*\)".*/\1/p' "$MODEL_MANIFEST")"
if [ -z "$VERSION" ] || [ -z "$MODEL_BRANCH" ]; then
    echo "Could not determine the application version or model branch." >&2
    exit 1
fi

for command_name in flatpak gpg sha256sum; do
    if ! command -v "$command_name" >/dev/null 2>&1; then
        echo "Missing required command: $command_name" >&2
        exit 1
    fi
done
if command -v flatpak-builder >/dev/null 2>&1; then
    run_flatpak_builder() {
        flatpak-builder "$@"
    }
elif flatpak info --user org.flatpak.Builder >/dev/null 2>&1 \
    || flatpak info org.flatpak.Builder >/dev/null 2>&1; then
    GPG_AGENT_DIR="$(dirname "$(gpgconf --list-dirs agent-socket)")"
    run_flatpak_builder() {
        flatpak run --filesystem="$(pwd)" --filesystem="$SIGNING_HOME" \
            --filesystem="$GPG_AGENT_DIR" org.flatpak.Builder "$@"
    }
else
    echo "Missing required command: flatpak-builder" >&2
    echo "Install flatpak-builder or the org.flatpak.Builder Flatpak, then rerun this script." >&2
    exit 1
fi

if ! gpg --homedir "$SIGNING_HOME" --batch --list-secret-keys \
    "$SIGNING_KEY" >/dev/null 2>&1; then
    echo "The dedicated IMBOARD release-signing key is unavailable." >&2
    echo "Expected fingerprint: $SIGNING_KEY" >&2
    echo "Expected keyring: $SIGNING_HOME" >&2
    exit 1
fi

ARCH="$(flatpak --default-arch)"
BUNDLE="imboard-${VERSION}-${ARCH}.flatpak"
MODEL_BUNDLE="imboard-model-small-en-${VERSION}-${ARCH}.flatpak"
CHECKSUMS="imboard-${VERSION}-${ARCH}-SHA256SUMS"
CHECKSUM_SIGNATURE="${CHECKSUMS}.asc"

flatpak remote-add --user --if-not-exists flathub "$RUNTIME_REPO"
flatpak install --user --noninteractive flathub org.kde.Sdk//6.10 org.kde.Platform//6.10
run_flatpak_builder --user --install --force-clean --repo="$REPO_DIR" \
    --gpg-sign="$SIGNING_KEY" --gpg-homedir="$SIGNING_HOME" \
    "$BUILD_DIR" "$MANIFEST"
run_flatpak_builder --user --force-clean --repo="$REPO_DIR" \
    --gpg-sign="$SIGNING_KEY" --gpg-homedir="$SIGNING_HOME" \
    "$MODEL_BUILD_DIR" "$MODEL_MANIFEST"
flatpak build-bundle --runtime-repo="$RUNTIME_REPO" "$REPO_DIR" "$BUNDLE" "$APP_ID"
flatpak build-bundle --runtime "$REPO_DIR" "$MODEL_BUNDLE" \
    "$MODEL_ID" "$MODEL_BRANCH"
sha256sum "$BUNDLE" "$MODEL_BUNDLE" > "$CHECKSUMS"
gpg --homedir "$SIGNING_HOME" --yes --local-user "$SIGNING_KEY" \
    --armor --detach-sign --output "$CHECKSUM_SIGNATURE" "$CHECKSUMS"

cat <<EOF

Release bundles created:
  ${BUNDLE}
  ${MODEL_BUNDLE}
  ${CHECKSUMS}
  ${CHECKSUM_SIGNATURE}

Public key to include with the GitHub release:
  ${PUBLIC_KEY}

Release signing fingerprint:
  ${SIGNING_KEY}

Test the lightweight keyboard install with:
  flatpak install --user ./${BUNDLE}

Then test the optional offline transcription model with:
  flatpak install --user ./${MODEL_BUNDLE}

Verify the checksums with:
  gpg --verify ${CHECKSUM_SIGNATURE} ${CHECKSUMS}
  sha256sum --check ${CHECKSUMS}
EOF
