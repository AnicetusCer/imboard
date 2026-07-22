#!/usr/bin/env bash
# SPDX-FileCopyrightText: 2026 AnicetusCer
# SPDX-License-Identifier: GPL-3.0-or-later

set -euo pipefail

if [[ -z "${DBUS_SESSION_BUS_ADDRESS:-}" ]]; then
    if ! command -v dbus-run-session >/dev/null 2>&1; then
        echo "dbus-run-session is required for the lifecycle test" >&2
        exit 1
    fi
    exec dbus-run-session -- "$0" "$@"
fi

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

# A compositor or sandbox crash can leave the long-lived lock and socket in
# place. The next launch must recover them without manual cleanup.
"${binary}" --start-hidden &
first_pid=$!
sleep 0.5
kill -KILL "${first_pid}"
wait "${first_pid}" 2>/dev/null || true
first_pid=
test -e "${runtime_dir}/imboard-window.lock"

"${binary}" --toggle &
first_pid=$!
sleep 0.75
kill -0 "${first_pid}"
"${binary}" --quit
wait "${first_pid}"
first_pid=

# A missing control socket must not let a second process replace the runtime
# state while the D-Bus liveness lease still proves the first process is alive.
"${binary}" --start-hidden &
first_pid=$!
sleep 0.5
rm -f "${runtime_dir}/imboard-window.sock"
if "${binary}" --toggle; then
    echo "A second Imboard instance started while the primary process was alive" >&2
    exit 1
fi
kill -TERM "${first_pid}"
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
