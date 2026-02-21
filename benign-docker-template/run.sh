#!/usr/bin/env bash
set -euo pipefail

IMAGE_NAME="${IMAGE_NAME:-benign-service}"
CONTAINER_NAME="${CONTAINER_NAME:-benign_service}"
DOCKER_PLATFORM="${DOCKER_PLATFORM:-linux/amd64}"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
MOUNT_SOURCE="${MOUNT_SOURCE:-$SCRIPT_DIR/mount}"
CONTAINER_MOUNT_TARGET="${CONTAINER_MOUNT_TARGET:-/opt/app/mount}"
ENV_FILE="${ENV_FILE:-$SCRIPT_DIR/.env}"

HOST_PORT="${HOST_PORT:-50051}"
CONTAINER_PORT="${CONTAINER_PORT:-50051}"

log() { printf '==> %s\n' "$*"; }
warn() { printf 'WARN: %s\n' "$*" >&2; }
die() { printf 'ERROR: %s\n' "$*" >&2; exit 1; }

docker_can_bind_mount_path() {
  local src="$1"
  docker run --rm \
    --platform "$DOCKER_PLATFORM" \
    --mount "type=bind,source=$src,target=/mnt,readonly" \
    --entrypoint /bin/sh \
    alpine:3.20 -c 'true' >/dev/null 2>&1
}

build_image() {
  log "Building $IMAGE_NAME:latest for platform $DOCKER_PLATFORM"
  docker build --platform "$DOCKER_PLATFORM" -t "$IMAGE_NAME:latest" "$SCRIPT_DIR"
}

main() {
  local -a mount_args=()
  local -a env_args=()

  build_image

  if [ -f "$ENV_FILE" ]; then
    env_args=(--env-file "$ENV_FILE")
    log "Using env file: $ENV_FILE"
  else
    warn "No env file found at $ENV_FILE. Using image defaults."
  fi

  if [ -d "$MOUNT_SOURCE" ] && docker_can_bind_mount_path "$MOUNT_SOURCE"; then
    mount_args=(--mount "type=bind,source=$MOUNT_SOURCE,target=$CONTAINER_MOUNT_TARGET")
    log "Bind mount enabled: $MOUNT_SOURCE -> $CONTAINER_MOUNT_TARGET"
  else
    warn "Bind mount unavailable for current Docker context: $MOUNT_SOURCE"
    warn "Falling back to no-bind mode."
  fi

  docker rm -f "$CONTAINER_NAME" >/dev/null 2>&1 || true

  log "Starting container $CONTAINER_NAME on localhost:$HOST_PORT"
  docker run -d \
    --name "$CONTAINER_NAME" \
    --platform "$DOCKER_PLATFORM" \
    -p "${HOST_PORT}:${CONTAINER_PORT}" \
    "${env_args[@]}" \
    "${mount_args[@]}" \
    "$IMAGE_NAME:latest" >/dev/null

  log "Container started. Health check: curl -fsS http://127.0.0.1:${HOST_PORT}/health"
}

main "$@"
