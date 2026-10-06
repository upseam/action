#!/usr/bin/env bash
set -uo pipefail
token="$(od -An -tx1 -N16 /dev/urandom | tr -d ' \n')"
echo "::stop-commands::$token"
status=0
"$@" 2>&1 | tee "${UPSEAM_LOG:-/dev/null}" || status=$?
echo "::$token::"
exit "$status"
