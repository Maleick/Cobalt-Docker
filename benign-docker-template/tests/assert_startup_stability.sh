#!/usr/bin/env bash
set -euo pipefail

CONTAINER_NAME="${1:-benign_service}"
LOG_LINES="${LOG_LINES:-250}"

log() { printf '==> %s\n' "$*"; }
die() { printf 'ERROR: %s\n' "$*" >&2; exit 1; }

logs="$(docker logs --tail "$LOG_LINES" "$CONTAINER_NAME" 2>&1 || true)"
[ -n "$logs" ] || die "No logs found for container '$CONTAINER_NAME'."

echo "$logs" | grep -q "Starting default app\|Starting custom command" || \
  die "Startup marker not found in logs."

if echo "$logs" | grep -q "ERROR:"; then
  echo "$logs" >&2
  die "Fatal error marker found in logs."
fi

if ! docker inspect -f '{{.State.Running}}' "$CONTAINER_NAME" 2>/dev/null | grep -q true; then
  die "Container '$CONTAINER_NAME' is not running."
fi

log "Startup stability assertion passed for '$CONTAINER_NAME'."
