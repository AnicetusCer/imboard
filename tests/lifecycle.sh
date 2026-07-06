#!/usr/bin/env bash
# SPDX-FileCopyrightText: 2026 AnicetusCer
# SPDX-License-Identifier: GPL-3.0-or-later

set -euo pipefail

binary=$1
runtime_dir=$(mktemp -d)
first_pid=
second_pid=

cleanup() {
    if [[ -n "${first_pid}" ]]; then kill -KILL "${first_pid}" 2>/dev/null || true; fi
    if [[ -n "${second_pid}" ]]; then kill -KILL "${second_pid}" 2>/dev/null || true; fi
    rm -rf "${runtime_dir}"
}
trap cleanup EXIT

export XDG_RUNTIME_DIR="${runtime_dir}"
export XDG_CONFIG_HOME="${runtime_dir}/config"
export QT_QPA_PLATFORM=offscreen

"${binary}" --start-hidden &
first_pid=$!
sleep 0.5

"${binary}" --toggle
"${binary}" --toggle
"${binary}"
kill -0 "${first_pid}"
"${binary}" --quit
wait "${first_pid}"
first_pid=

"${binary}" --toggle &
first_pid=$!
sleep 0.75
kill -0 "${first_pid}"
"${binary}" --quit
wait "${first_pid}"
first_pid=

"${binary}" &
second_pid=$!
sleep 0.5
kill -TERM "${second_pid}"
wait "${second_pid}"
second_pid=

"${binary}" &
second_pid=$!
sleep 0.5
kill -INT "${second_pid}"
wait "${second_pid}"
second_pid=
