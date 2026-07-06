#!/usr/bin/env bash
# SPDX-FileCopyrightText: 2026 AnicetusCer
# SPDX-License-Identifier: GPL-3.0-or-later

set -euo pipefail

binary=$1
runtime_dir=$(mktemp -d)
trap 'rm -rf "${runtime_dir}"' EXIT
chmod 700 "${runtime_dir}"

export XDG_RUNTIME_DIR="${runtime_dir}"
export XDG_CONFIG_HOME="${runtime_dir}/config"
export QT_QPA_PLATFORM=offscreen

"${binary}" --smoke-test
