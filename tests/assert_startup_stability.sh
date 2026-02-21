#!/usr/bin/env bash

set -euo pipefail

CONTAINER_NAME="${1:-cobaltstrike_server}"
LOG_PATH="${2:-}"
HANDSHAKE_PATTERN="${HANDSHAKE_PATTERN:-Remote host terminated the handshake}"
STARTUP_PATTERN="${STARTUP_PATTERN:-Tomcat started on port|Started StartApi|teamserver and csrestapi are running and healthy}"
FATAL_PATTERN="${FATAL_PATTERN:-Error: csrestapi exited unexpectedly|Error: teamserver exited unexpectedly|Error: REST API healthcheck failed|did not become TLS-ready|exited before becoming healthy}"

if [ -z "$LOG_PATH" ]; then
    LOG_PATH="$(mktemp)"
    docker logs "$CONTAINER_NAME" >"$LOG_PATH" 2>&1
fi

if [ ! -f "$LOG_PATH" ]; then
    echo "Error: log file not found: $LOG_PATH"
    exit 1
fi

if grep -Eq "$FATAL_PATTERN" "$LOG_PATH"; then
    echo "FAIL: fatal startup marker(s) found in logs."
    grep -En "$FATAL_PATTERN" "$LOG_PATH" || true
    exit 1
fi

if grep -Eq "$HANDSHAKE_PATTERN" "$LOG_PATH"; then
    last_handshake_line="$(grep -En "$HANDSHAKE_PATTERN" "$LOG_PATH" | tail -n 1 | cut -d: -f1)"
    startup_after="$(awk -v from_line="$last_handshake_line" -v re="$STARTUP_PATTERN" 'NR > from_line && $0 ~ re { print $0; exit }' "$LOG_PATH")"

    if [ -z "$startup_after" ]; then
        echo "FAIL: handshake warning detected without a later startup marker."
        echo "Last handshake line: $last_handshake_line"
        exit 1
    fi

    echo "PASS: handshake warning detected but startup remained stable."
    echo "Startup marker after warning: $startup_after"
    exit 0
fi

if grep -Eq "$STARTUP_PATTERN" "$LOG_PATH"; then
    echo "PASS: no handshake warning detected and startup markers are present."
    exit 0
fi

echo "FAIL: no handshake warning and no known startup marker found."
exit 1
