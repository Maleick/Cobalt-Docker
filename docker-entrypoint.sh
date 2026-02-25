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
TS_USERSPACE="${TS_USERSPACE:-false}"
USE_TAILSCALE_IP="${USE_TAILSCALE_IP:-false}"

TEAMSERVER_PID=""
REST_PID=""
TS_PID=""
STARTUP_TAG="STARTUP"

cleanup() {
    local exit_code="$?"

    if [ -n "$REST_PID" ] && kill -0 "$REST_PID" 2>/dev/null; then
        kill "$REST_PID" 2>/dev/null || true
    fi

    if [ -n "$TEAMSERVER_PID" ] && kill -0 "$TEAMSERVER_PID" 2>/dev/null; then
        kill "$TEAMSERVER_PID" 2>/dev/null || true
    fi

    if [ -n "$TS_PID" ] && kill -0 "$TS_PID" 2>/dev/null; then
        kill "$TS_PID" 2>/dev/null || true
    fi

    wait 2>/dev/null || true
    exit "$exit_code"
}

trap cleanup EXIT INT TERM

log_phase() {
    local phase="$1"
    shift
    printf '%s[%s] %s\n' "$STARTUP_TAG" "$phase" "$*"
}

fail_phase() {
    local phase="$1"
    shift
    printf '%s[%s] ERROR: %s\n' "$STARTUP_TAG" "$phase" "$*" >&2
    exit 1
}

is_valid_port() {
    local port="$1"
    [[ "$port" =~ ^[0-9]+$ ]] && [ "$port" -ge 1 ] && [ "$port" -le 65535 ]
}

normalize_bool_or_fail() {
    local phase="$1"
    local key="$2"
    local value="$3"

    value="$(printf '%s' "$value" | tr '[:upper:]' '[:lower:]')"

    case "$value" in
        true|false)
            printf '%s' "$value"
            ;;
        *)
            fail_phase "$phase" "$key must be 'true' or 'false' (got '$3')."
            ;;
    esac
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

wait_for_teamserver_tls_readiness() {
    local phase="teamserver-ready"
    local endpoint="$UPSTREAM_HOST:$UPSTREAM_PORT"

    log_phase "$phase" "waiting for TLS readiness on $endpoint (timeout=60s)"
    for _ in $(seq 1 60); do
        if ! kill -0 "$TEAMSERVER_PID" 2>/dev/null; then
            fail_phase "$phase" "teamserver exited before becoming TLS-ready on $endpoint"
        fi

        if tls_probe_endpoint "$UPSTREAM_HOST" "$UPSTREAM_PORT"; then
            log_phase "$phase" "TLS readiness confirmed on $endpoint"
            return
        fi

        sleep 1
    done

    fail_phase "$phase" "teamserver did not become TLS-ready on $endpoint within 60s"
}

wait_for_rest_healthcheck() {
    local phase="rest-ready"

    log_phase "$phase" "waiting for HTTPS healthcheck at $HEALTHCHECK_URL (insecure=$HEALTHCHECK_INSECURE, timeout=60s)"
    for _ in $(seq 1 60); do
        if ! kill -0 "$TEAMSERVER_PID" 2>/dev/null; then
            fail_phase "$phase" "teamserver exited while waiting for REST API health at $HEALTHCHECK_URL"
        fi

        if ! kill -0 "$REST_PID" 2>/dev/null; then
            fail_phase "$phase" "csrestapi exited before becoming healthy at $HEALTHCHECK_URL"
        fi

        if http_healthcheck "$HEALTHCHECK_URL" "$HEALTHCHECK_INSECURE"; then
            log_phase "$phase" "REST API healthcheck reachable at $HEALTHCHECK_URL"
            return
        fi

        sleep 1
    done

    fail_phase "$phase" "REST API healthcheck failed at $HEALTHCHECK_URL within 60s"
}

monitor_runtime_processes() {
    log_phase "monitor" "startup complete; monitoring teamserver and csrestapi processes"
    wait -n "$TEAMSERVER_PID" "$REST_PID" || true

    if kill -0 "$TEAMSERVER_PID" 2>/dev/null; then
        fail_phase "monitor" "csrestapi exited unexpectedly while teamserver is still running"
    fi

    if kill -0 "$REST_PID" 2>/dev/null; then
        fail_phase "monitor" "teamserver exited unexpectedly while csrestapi is still running"
    fi

    fail_phase "monitor" "teamserver and csrestapi exited"
}

log_phase "preflight" "validating startup inputs"
if [ "$#" -lt 2 ] || [ "$#" -gt 3 ]; then
    fail_phase "preflight" "usage: $0 <external-ip> <teamserver-password> [malleable-profile]"
fi

if [ ! -x "$TEAMSERVER_BIN" ]; then
    fail_phase "preflight" "teamserver binary not found at $TEAMSERVER_BIN"
fi

if [ ! -x "$REST_SERVER_BIN" ]; then
    fail_phase "preflight" "csrestapi binary not found at $REST_SERVER_BIN"
fi

if ! is_valid_port "$SERVICE_PORT"; then
    fail_phase "preflight" "SERVICE_PORT must be an integer between 1 and 65535 (got '$SERVICE_PORT')"
fi

if ! is_valid_port "$UPSTREAM_PORT"; then
    fail_phase "preflight" "UPSTREAM_PORT must be an integer between 1 and 65535 (got '$UPSTREAM_PORT')"
fi

HEALTHCHECK_INSECURE="$(normalize_bool_or_fail "preflight" "HEALTHCHECK_INSECURE" "$HEALTHCHECK_INSECURE")"
TS_USERSPACE="$(normalize_bool_or_fail "preflight" "TS_USERSPACE" "$TS_USERSPACE")"
USE_TAILSCALE_IP="$(normalize_bool_or_fail "preflight" "USE_TAILSCALE_IP" "$USE_TAILSCALE_IP")"

TEAMSERVER_HOST="$1"
TEAMSERVER_PASSWORD="$2"
TEAMSERVER_PROFILE="${3:-}"

if [ -n "${TS_AUTHKEY:-}" ]; then
    log_phase "tailscale" "starting tailscaled"
    TS_TUN_ARGS="--tun=tailscale0"
    if [ "$TS_USERSPACE" = "true" ]; then
        TS_TUN_ARGS="--tun=userspace-networking"
    fi

    tailscaled ${TS_TUN_ARGS} --state=mem: --socks5-server=localhost:1055 --outbound-http-proxy-listen=localhost:1055 &
    TS_PID="$!"

    log_phase "tailscale" "waiting for tailscaled availability"
    for _ in $(seq 1 10); do
        if tailscale status >/dev/null 2>&1; then
            break
        fi
        sleep 1
    done

    log_phase "tailscale" "authenticating to tailnet"
    tailscale up --authkey="${TS_AUTHKEY}" ${TS_EXTRA_ARGS:-}

    if [ "$USE_TAILSCALE_IP" = "true" ]; then
        log_phase "tailscale" "waiting for tailscale IPv4 address"
        for _ in $(seq 1 30); do
            TS_IP=$(tailscale ip -4)
            if [ -n "$TS_IP" ]; then
                TEAMSERVER_HOST="$TS_IP"
                log_phase "tailscale" "overriding TEAMSERVER_HOST with tailscale IP $TEAMSERVER_HOST"
                break
            fi
            sleep 1
        done
    fi
fi

TEAMSERVER_CMD=("$TEAMSERVER_BIN" "$TEAMSERVER_HOST" "$TEAMSERVER_PASSWORD")
if [ -n "$TEAMSERVER_PROFILE" ]; then
    TEAMSERVER_CMD+=("$TEAMSERVER_PROFILE")
fi
TEAMSERVER_CMD+=("--experimental-db")

log_phase "teamserver-launch" "starting teamserver with --experimental-db"
"${TEAMSERVER_CMD[@]}" &
TEAMSERVER_PID="$!"

wait_for_teamserver_tls_readiness

log_phase "rest-launch" "starting csrestapi with user '$REST_API_USER'"
(
    cd "$REST_SERVER_DIR"
    SERVER_ADDRESS="$SERVICE_BIND_HOST" \
    SERVER_PORT="$SERVICE_PORT" \
    ./csrestapi --user "$REST_API_USER" --pass "$TEAMSERVER_PASSWORD" --host "$UPSTREAM_HOST" --port "$UPSTREAM_PORT"
) &
REST_PID="$!"

wait_for_rest_healthcheck
monitor_runtime_processes
