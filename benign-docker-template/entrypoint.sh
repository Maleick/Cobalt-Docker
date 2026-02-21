#!/usr/bin/env bash
set -euo pipefail

APP_BIND_HOST="${APP_BIND_HOST:-0.0.0.0}"
APP_PORT="${APP_PORT:-50051}"
APP_CMD="${APP_CMD:-}"

TS_ENABLE="${TS_ENABLE:-false}"
TS_REQUIRED="${TS_REQUIRED:-false}"
TS_AUTHKEY="${TS_AUTHKEY:-}"
TS_HOSTNAME="${TS_HOSTNAME:-app-node}"
TS_TUN_MODE="${TS_TUN_MODE:-userspace}"
TS_STATE_DIR="${TS_STATE_DIR:-/var/lib/tailscale}"
TS_SERVE_ENABLE="${TS_SERVE_ENABLE:-false}"
TS_SERVE_TARGETS="${TS_SERVE_TARGETS:-}"
TS_SOCKET="${TS_SOCKET:-/var/run/tailscale/tailscaled.sock}"

log() { printf '==> %s\n' "$*"; }
warn() { printf 'WARN: %s\n' "$*" >&2; }
die() { printf 'ERROR: %s\n' "$*" >&2; exit 1; }

is_true() {
  case "${1,,}" in
    1|true|yes|on) return 0 ;;
    *) return 1 ;;
  esac
}

ts_warn_or_die() {
  if is_true "$TS_REQUIRED"; then
    die "$1"
  fi
  warn "$1"
}

start_tailscaled() {
  local tun_mode
  case "${TS_TUN_MODE,,}" in
    userspace) tun_mode="userspace-networking" ;;
    kernel) tun_mode="tun" ;;
    *) ts_warn_or_die "Unsupported TS_TUN_MODE='$TS_TUN_MODE'. Use userspace or kernel."; return 1 ;;
  esac

  mkdir -p "$TS_STATE_DIR" "$(dirname "$TS_SOCKET")"
  log "Starting tailscaled (mode: ${TS_TUN_MODE,,})"
  tailscaled \
    --state="${TS_STATE_DIR}/tailscaled.state" \
    --socket="$TS_SOCKET" \
    --tun="$tun_mode" \
    >/tmp/tailscaled.log 2>&1 &
  local tailscaled_pid=$!

  for _ in $(seq 1 30); do
    if tailscale --socket "$TS_SOCKET" version >/dev/null 2>&1; then
      return 0
    fi
    if ! kill -0 "$tailscaled_pid" >/dev/null 2>&1; then
      break
    fi
    sleep 1
  done

  if [ -f /tmp/tailscaled.log ]; then
    warn "tailscaled log tail:"
    tail -n 20 /tmp/tailscaled.log >&2 || true
  fi
  ts_warn_or_die "tailscaled did not become ready."
  return 1
}

configure_tailscale_up() {
  if [ -z "$TS_AUTHKEY" ]; then
    ts_warn_or_die "TS_AUTHKEY is empty; skipping tailscale up."
    return 1
  fi

  log "Running tailscale up (hostname: $TS_HOSTNAME)"
  if ! tailscale --socket "$TS_SOCKET" up \
    --authkey="$TS_AUTHKEY" \
    --hostname="$TS_HOSTNAME"; then
    ts_warn_or_die "tailscale up failed."
    return 1
  fi
  return 0
}

configure_tailscale_serve() {
  if ! is_true "$TS_SERVE_ENABLE"; then
    return 0
  fi

  if [ -z "$TS_SERVE_TARGETS" ]; then
    ts_warn_or_die "TS_SERVE_ENABLE=true but TS_SERVE_TARGETS is empty."
    return 1
  fi

  local rule src_port dst_host dst_port target
  IFS=',' read -r -a rules <<< "$TS_SERVE_TARGETS"
  for rule in "${rules[@]}"; do
    rule="$(echo "$rule" | xargs)"
    if [[ "$rule" =~ ^tcp:([0-9]+)\-\>([^:]+):([0-9]+)$ ]]; then
      src_port="${BASH_REMATCH[1]}"
      dst_host="${BASH_REMATCH[2]}"
      dst_port="${BASH_REMATCH[3]}"
      target="tcp://${dst_host}:${dst_port}"
      log "Configuring tailscale serve: tcp:${src_port} -> ${target}"
      if ! tailscale --socket "$TS_SOCKET" serve --bg "tcp:${src_port}" "$target"; then
        ts_warn_or_die "Failed to configure serve rule '$rule'."
        return 1
      fi
    else
      ts_warn_or_die "Invalid TS_SERVE_TARGETS rule '$rule'. Format: tcp:<port>-><host>:<port>"
      return 1
    fi
  done

  return 0
}

start_default_app() {
  exec python3 /opt/app/app.py --host "$APP_BIND_HOST" --port "$APP_PORT"
}

main() {
  if is_true "$TS_ENABLE"; then
    start_tailscaled || true
    configure_tailscale_up || true
    configure_tailscale_serve || true
  else
    log "Tailscale disabled (TS_ENABLE=false)."
  fi

  if [ "$#" -gt 0 ]; then
    log "Starting custom command from arguments."
    exec "$@"
  fi

  if [ -n "$APP_CMD" ]; then
    log "Starting custom command from APP_CMD."
    exec bash -lc "$APP_CMD"
  fi

  log "Starting default app on ${APP_BIND_HOST}:${APP_PORT}."
  start_default_app
}

main "$@"
