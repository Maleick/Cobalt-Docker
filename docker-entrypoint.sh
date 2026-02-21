#!/bin/bash

set -euo pipefail

TEAMSERVER_BIN="/opt/cobaltstrike/server/teamserver"
REST_SERVER_DIR="/opt/cobaltstrike/server/rest-server"
REST_SERVER_BIN="$REST_SERVER_DIR/csrestapi"
REST_API_USER="${REST_API_USER:-csrestapi}"
SERVICE_BIND_HOST="${SERVICE_BIND_HOST:-0.0.0.0}"
SERVICE_PORT="${SERVICE_PORT:-50443}"
UPSTREAM_HOST="${UPSTREAM_HOST:-127.0.0.1}"
UPSTREAM_PORT="${UPSTREAM_PORT:-50050}"
HEALTHCHECK_INSECURE="${HEALTHCHECK_INSECURE:-true}"
HEALTHCHECK_URL="${HEALTHCHECK_URL:-https://127.0.0.1:${SERVICE_PORT}/health}"

TEAMSERVER_PID=""
REST_PID=""

cleanup() {
    local exit_code="$?"

    if [ -n "$REST_PID" ] && kill -0 "$REST_PID" 2>/dev/null; then
        kill "$REST_PID" 2>/dev/null || true
    fi

    if [ -n "$TEAMSERVER_PID" ] && kill -0 "$TEAMSERVER_PID" 2>/dev/null; then
        kill "$TEAMSERVER_PID" 2>/dev/null || true
    fi

    wait 2>/dev/null || true
    exit "$exit_code"
}

trap cleanup EXIT INT TERM

is_valid_port() {
    local port="$1"
    [[ "$port" =~ ^[0-9]+$ ]] && [ "$port" -ge 1 ] && [ "$port" -le 65535 ]
}

tls_probe_endpoint() {
    local host="$1"
    local port="$2"
    openssl s_client -connect "${host}:${port}" -servername "$host" -brief </dev/null >/dev/null 2>&1
}

http_healthcheck() {
    local healthcheck_url="$1"
    local insecure_mode="$2"
    local http_code=""
    local -a curl_args=(--silent --show-error --max-time 5 --output /dev/null --write-out '%{http_code}')

    if [ "$insecure_mode" = "true" ]; then
        curl_args+=(--insecure)
    fi

    http_code="$(curl "${curl_args[@]}" "$healthcheck_url")" || return 1

    if ! [[ "$http_code" =~ ^[0-9]{3}$ ]]; then
        return 1
    fi

    # 2xx-4xx confirms HTTPS listener and HTTP stack are up.
    # 401/403 are common for auth-protected health paths.
    if [ "$http_code" -ge 200 ] && [ "$http_code" -le 499 ]; then
        return 0
    fi

    return 1
}

if [ "$#" -lt 2 ] || [ "$#" -gt 3 ]; then
    echo "Usage: $0 <external-ip> <teamserver-password> [malleable-profile]"
    exit 1
fi

if [ ! -x "$TEAMSERVER_BIN" ]; then
    echo "Error: teamserver binary not found at $TEAMSERVER_BIN"
    exit 1
fi

if [ ! -x "$REST_SERVER_BIN" ]; then
    echo "Error: csrestapi binary not found at $REST_SERVER_BIN"
    exit 1
fi

if ! is_valid_port "$SERVICE_PORT"; then
    echo "Error: SERVICE_PORT must be an integer between 1 and 65535 (got '$SERVICE_PORT')."
    exit 1
fi

if ! is_valid_port "$UPSTREAM_PORT"; then
    echo "Error: UPSTREAM_PORT must be an integer between 1 and 65535 (got '$UPSTREAM_PORT')."
    exit 1
fi

case "$HEALTHCHECK_INSECURE" in
    true|false)
        ;;
    *)
        echo "Error: HEALTHCHECK_INSECURE must be 'true' or 'false' (got '$HEALTHCHECK_INSECURE')."
        exit 1
        ;;
esac

TEAMSERVER_HOST="$1"
TEAMSERVER_PASSWORD="$2"
TEAMSERVER_PROFILE="${3:-}"

TEAMSERVER_CMD=("$TEAMSERVER_BIN" "$TEAMSERVER_HOST" "$TEAMSERVER_PASSWORD")
if [ -n "$TEAMSERVER_PROFILE" ]; then
    TEAMSERVER_CMD+=("$TEAMSERVER_PROFILE")
fi
TEAMSERVER_CMD+=("--experimental-db")

echo "==> Starting teamserver with --experimental-db..."
"${TEAMSERVER_CMD[@]}" &
TEAMSERVER_PID="$!"

echo "==> Waiting for teamserver TLS readiness on $UPSTREAM_HOST:$UPSTREAM_PORT..."
for _ in $(seq 1 60); do
    if ! kill -0 "$TEAMSERVER_PID" 2>/dev/null; then
        echo "Error: teamserver exited before becoming ready."
        exit 1
    fi

    if tls_probe_endpoint "$UPSTREAM_HOST" "$UPSTREAM_PORT"; then
        break
    fi

    sleep 1
done

if ! tls_probe_endpoint "$UPSTREAM_HOST" "$UPSTREAM_PORT"; then
    echo "Error: teamserver did not become TLS-ready on $UPSTREAM_HOST:$UPSTREAM_PORT within timeout."
    exit 1
fi

echo "==> Starting csrestapi with user '$REST_API_USER'..."
(
    cd "$REST_SERVER_DIR"
    SERVER_ADDRESS="$SERVICE_BIND_HOST" \
    SERVER_PORT="$SERVICE_PORT" \
    ./csrestapi --user "$REST_API_USER" --pass "$TEAMSERVER_PASSWORD" --host "$UPSTREAM_HOST" --port "$UPSTREAM_PORT"
) &
REST_PID="$!"

echo "==> Waiting for REST API healthcheck: $HEALTHCHECK_URL (insecure=$HEALTHCHECK_INSECURE)"
for _ in $(seq 1 60); do
    if ! kill -0 "$TEAMSERVER_PID" 2>/dev/null; then
        echo "Error: teamserver exited while waiting for REST API health."
        exit 1
    fi

    if ! kill -0 "$REST_PID" 2>/dev/null; then
        echo "Error: csrestapi exited before becoming healthy."
        exit 1
    fi

    if http_healthcheck "$HEALTHCHECK_URL" "$HEALTHCHECK_INSECURE"; then
        break
    fi

    sleep 1
done

if ! http_healthcheck "$HEALTHCHECK_URL" "$HEALTHCHECK_INSECURE"; then
    echo "Error: REST API healthcheck failed: $HEALTHCHECK_URL"
    exit 1
fi

echo "==> teamserver and csrestapi are running and healthy."
wait -n "$TEAMSERVER_PID" "$REST_PID" || true

if kill -0 "$TEAMSERVER_PID" 2>/dev/null; then
    echo "Error: csrestapi exited unexpectedly."
    exit 1
fi

if kill -0 "$REST_PID" 2>/dev/null; then
    echo "Error: teamserver exited unexpectedly."
    exit 1
fi

echo "Error: teamserver or csrestapi exited."
exit 1
