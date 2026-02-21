#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
IMAGE_NAME="${IMAGE_NAME:-benign-service-smoke}"
DOCKER_PLATFORM="${DOCKER_PLATFORM:-linux/amd64}"

log() { printf '==> %s\n' "$*"; }
die() { printf 'ERROR: %s\n' "$*" >&2; exit 1; }

cleanup_container() {
  local name="$1"
  docker rm -f "$name" >/dev/null 2>&1 || true
}

wait_for_health() {
  local port="$1"
  for _ in $(seq 1 25); do
    if curl -fsS "http://127.0.0.1:${port}/health" >/dev/null 2>&1; then
      return 0
    fi
    sleep 1
  done
  return 1
}

container_running() {
  local name="$1"
  docker inspect -f '{{.State.Running}}' "$name" 2>/dev/null | grep -q true
}

test_no_tailscale() {
  local name="smoke_no_tailscale"
  local port="51051"
  cleanup_container "$name"

  log "Test 1: TS_ENABLE=false should start app"
  docker run -d --name "$name" \
    --platform "$DOCKER_PLATFORM" \
    -p "${port}:50051" \
    -e TS_ENABLE=false \
    "$IMAGE_NAME:latest" >/dev/null

  wait_for_health "$port" || die "No tailscale mode failed health check."
  cleanup_container "$name"
}

test_optional_missing_authkey() {
  local name="smoke_optional_missing_key"
  local port="51052"
  cleanup_container "$name"

  log "Test 2: TS_ENABLE=true + TS_REQUIRED=false + empty key should continue"
  docker run -d --name "$name" \
    --platform "$DOCKER_PLATFORM" \
    -p "${port}:50051" \
    -e TS_ENABLE=true \
    -e TS_REQUIRED=false \
    -e TS_AUTHKEY= \
    "$IMAGE_NAME:latest" >/dev/null

  wait_for_health "$port" || die "Optional tailscale mode failed health check."
  cleanup_container "$name"
}

test_required_missing_authkey() {
  local name="smoke_required_missing_key"
  cleanup_container "$name"

  log "Test 3: TS_ENABLE=true + TS_REQUIRED=true + empty key should fail startup"
  docker run -d --name "$name" \
    --platform "$DOCKER_PLATFORM" \
    -e TS_ENABLE=true \
    -e TS_REQUIRED=true \
    -e TS_AUTHKEY= \
    "$IMAGE_NAME:latest" >/dev/null

  sleep 3
  if container_running "$name"; then
    cleanup_container "$name"
    die "Required tailscale mode unexpectedly kept container running."
  fi

  if ! docker logs "$name" 2>&1 | grep -q "TS_AUTHKEY is empty"; then
    docker logs "$name" >&2 || true
    cleanup_container "$name"
    die "Required-mode failure did not report missing TS_AUTHKEY."
  fi
  cleanup_container "$name"
}

main() {
  log "Building smoke image"
  docker build --platform "$DOCKER_PLATFORM" -t "$IMAGE_NAME:latest" "$PROJECT_DIR" >/dev/null

  test_no_tailscale
  test_optional_missing_authkey
  test_required_missing_authkey
  log "All smoke tests passed."
}

main "$@"
