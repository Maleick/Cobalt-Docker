#!/usr/bin/env bash

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SPEC_DIR="$ROOT_DIR/tests/spec"

if [ ! -d "$SPEC_DIR" ]; then
    echo "No spec directory found at $SPEC_DIR"
    exit 1
fi

status=0
ran=0

for spec in "$SPEC_DIR"/*.sh; do
    if [ ! -f "$spec" ]; then
        continue
    fi

    ran=$((ran + 1))
    echo "==> Running $(basename "$spec")"
    if bash "$spec"; then
        echo "PASS $(basename "$spec")"
    else
        echo "FAIL $(basename "$spec")"
        status=1
    fi
    echo

done

if [ "$ran" -eq 0 ]; then
    echo "No spec files found in $SPEC_DIR"
    exit 1
fi

if [ "$status" -ne 0 ]; then
    echo "Shell regression suite failed ($ran spec files)."
    exit "$status"
fi

echo "Shell regression suite passed ($ran spec files)."
