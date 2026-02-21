#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
CONFIG_FILE="${CONFIG_FILE:-$PROJECT_DIR/.env}"

IMAGE_NAME="${IMAGE_NAME:-cobaltstrike:latest}"
CONTAINER_NAME="${CONTAINER_NAME:-cobaltstrike_tls_smoke}"
DOCKER_PLATFORM="${DOCKER_PLATFORM:-linux/amd64}"
REST_API_USER="${REST_API_USER:-csrestapi}"

SERVICE_BIND_HOST="${SERVICE_BIND_HOST:-0.0.0.0}"
SERVICE_PORT="${SERVICE_PORT:-50443}"
UPSTREAM_HOST="${UPSTREAM_HOST:-127.0.0.1}"
UPSTREAM_PORT="${UPSTREAM_PORT:-50050}"
HEALTHCHECK_INSECURE="${HEALTHCHECK_INSECURE:-true}"
HOST_TEAMSERVER_PORT="${HOST_TEAMSERVER_PORT:-50050}"
HOST_REST_PORT="${HOST_REST_PORT:-50443}"
HEALTHCHECK_URL="${HEALTHCHECK_URL:-https://127.0.0.1:${HOST_REST_PORT}/health}"
ENTRYPOINT_HEALTHCHECK_URL="${ENTRYPOINT_HEALTHCHECK_URL:-https://127.0.0.1:${SERVICE_PORT}/health}"
HEALTHCHECK_RETRIES="${HEALTHCHECK_RETRIES:-90}"
HEALTHCHECK_INTERVAL_SECONDS="${HEALTHCHECK_INTERVAL_SECONDS:-2}"
PROFILE_CONTAINER_PATH="${PROFILE_CONTAINER_PATH:-/opt/cobaltstrike/mount/malleable.profile}"
TEAMSERVER_PASSWORD="${TEAMSERVER_PASSWORD:-}"
EXTERNAL_IP="${EXTERNAL_IP:-}"
CLEANUP="${CLEANUP:-true}"
LOG_PATH="${LOG_PATH:-$(mktemp -t cobalt_tls_smoke)}"

get_env_value() {
    local key="$1"
    awk -v wanted_key="$key" '
        /^[[:space:]]*#/ { next }
        {
            line=$0
            sub(/^[[:space:]]+/, "", line)
            if (line ~ /^export[[:space:]]+/) {
                sub(/^export[[:space:]]+/, "", line)
            }
            if (line ~ ("^" wanted_key "[[:space:]]*=")) {
                sub(/^[^=]*=/, "", line)
                gsub(/^["'"'"']|["'"'"']$/, "", line)
                print line
                exit
            }
        }
    ' "$CONFIG_FILE"
}

is_valid_port() {
    local port="$1"
    [[ "$port" =~ ^[0-9]+$ ]] && [ "$port" -ge 1 ] && [ "$port" -le 65535 ]
}

detect_host_ip() {
    local os_name
    os_name="$(uname)"

    if [ "$os_name" = "Linux" ]; then
        hostname -I | awk '{print $1}'
    elif [ "$os_name" = "Darwin" ]; then
        ifconfig en0 | awk '/inet / {print $2; exit}'
    fi
}

healthcheck() {
    local http_code=""
    local -a curl_args=(--silent --show-error --max-time 5 --output /dev/null --write-out '%{http_code}')

    if [ "$HEALTHCHECK_INSECURE" = "true" ]; then
        curl_args+=(--insecure)
    fi

    http_code="$(curl "${curl_args[@]}" "$HEALTHCHECK_URL")" || return 1

    if ! [[ "$http_code" =~ ^[0-9]{3}$ ]]; then
        return 1
    fi

    # 2xx-4xx confirms HTTPS listener and HTTP routing are live.
    if [ "$http_code" -ge 200 ] && [ "$http_code" -le 499 ]; then
        return 0
    fi

    return 1
}

cleanup() {
    local exit_code="$?"

    if [ "$CLEANUP" = "true" ]; then
        docker rm -f "$CONTAINER_NAME" >/dev/null 2>&1 || true
    fi

    exit "$exit_code"
}

trap cleanup EXIT INT TERM

for port_var in SERVICE_PORT UPSTREAM_PORT HOST_TEAMSERVER_PORT HOST_REST_PORT; do
    if ! is_valid_port "${!port_var}"; then
        echo "Error: $port_var must be an integer between 1 and 65535."
        exit 1
    fi
done

if [ "$HEALTHCHECK_INSECURE" != "true" ] && [ "$HEALTHCHECK_INSECURE" != "false" ]; then
    echo "Error: HEALTHCHECK_INSECURE must be true or false."
    exit 1
fi

if [ -z "$TEAMSERVER_PASSWORD" ] && [ -f "$CONFIG_FILE" ]; then
    TEAMSERVER_PASSWORD="$(get_env_value "TEAMSERVER_PASSWORD" || true)"
fi

if [ -z "$TEAMSERVER_PASSWORD" ]; then
    echo "Error: TEAMSERVER_PASSWORD is required (set env var or provide $CONFIG_FILE)."
    exit 1
fi

if [ -z "$EXTERNAL_IP" ]; then
    EXTERNAL_IP="$(detect_host_ip)"
fi

if [ -z "$EXTERNAL_IP" ]; then
    echo "Error: unable to determine EXTERNAL_IP. Set EXTERNAL_IP explicitly."
    exit 1
fi

if ! docker image inspect "$IMAGE_NAME" >/dev/null 2>&1; then
    echo "Error: Docker image not found: $IMAGE_NAME"
    echo "Build the image first (for example with ./cobalt-docker.sh)."
    exit 1
fi

docker rm -f "$CONTAINER_NAME" >/dev/null 2>&1 || true

echo "==> Starting detached container: $CONTAINER_NAME"
docker run -d --name "$CONTAINER_NAME" \
  --platform "$DOCKER_PLATFORM" \
  -e "REST_API_USER=$REST_API_USER" \
  -e "SERVICE_BIND_HOST=$SERVICE_BIND_HOST" \
  -e "SERVICE_PORT=$SERVICE_PORT" \
  -e "UPSTREAM_HOST=$UPSTREAM_HOST" \
  -e "UPSTREAM_PORT=$UPSTREAM_PORT" \
  -e "HEALTHCHECK_URL=$ENTRYPOINT_HEALTHCHECK_URL" \
  -e "HEALTHCHECK_INSECURE=$HEALTHCHECK_INSECURE" \
  -p "${HOST_TEAMSERVER_PORT}:50050" \
  -p "127.0.0.1:${HOST_REST_PORT}:${SERVICE_PORT}" \
  "$IMAGE_NAME" \
  "$EXTERNAL_IP" \
  "$TEAMSERVER_PASSWORD" \
  "$PROFILE_CONTAINER_PATH" >/dev/null

echo "==> Polling health URL: $HEALTHCHECK_URL"
healthy=false
for _ in $(seq 1 "$HEALTHCHECK_RETRIES"); do
    if [ "$(docker inspect -f '{{.State.Running}}' "$CONTAINER_NAME")" != "true" ]; then
        echo "Error: container exited before becoming healthy."
        docker logs "$CONTAINER_NAME" >"$LOG_PATH" 2>&1 || true
        exit 1
    fi

    if healthcheck; then
        healthy=true
        break
    fi

    sleep "$HEALTHCHECK_INTERVAL_SECONDS"
done

if [ "$healthy" != "true" ]; then
    echo "Error: healthcheck did not succeed within timeout."
    docker logs "$CONTAINER_NAME" >"$LOG_PATH" 2>&1 || true
    exit 1
fi

echo "==> Verifying TLS negotiation with openssl"
if ! openssl s_client -connect "127.0.0.1:${HOST_REST_PORT}" -servername localhost -brief </dev/null >/dev/null 2>&1; then
    echo "Error: openssl TLS probe failed."
    docker logs "$CONTAINER_NAME" >"$LOG_PATH" 2>&1 || true
    exit 1
fi

docker logs "$CONTAINER_NAME" >"$LOG_PATH" 2>&1 || true
"$SCRIPT_DIR/assert_startup_stability.sh" "$CONTAINER_NAME" "$LOG_PATH"

echo "PASS: smoke TLS handshake test succeeded. Logs: $LOG_PATH"
