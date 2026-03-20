#!/bin/bash

#
# This script builds and runs the Cobalt Strike Docker container.
#

set -euo pipefail

# --- Configuration ---
# Name for the Docker image
DOCKER_IMAGE_NAME="cobaltstrike"
# Container name is loaded from .env (CONTAINER_NAME) or defaults
DOCKER_CONTAINER_NAME=""
DOCKER_PLATFORM="${DOCKER_PLATFORM:-${COBALT_DOCKER_PLATFORM:-linux/amd64}}"
CONTAINER_MOUNT_TARGET="/opt/cobaltstrike/mount"

# Directory of this script. We use this as the canonical repo root even when
# the script is invoked from another working directory.
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_FILE="$SCRIPT_DIR/.env"

# Allow override via environment variable if Docker cannot access SCRIPT_DIR
# (e.g., on macOS when /opt is not shared with the Docker backend).
# MOUNT_SOURCE is the generic override; COBALT_DOCKER_MOUNT_SOURCE remains
# supported for backward compatibility.
MOUNT_SOURCE="${MOUNT_SOURCE:-${COBALT_DOCKER_MOUNT_SOURCE:-$SCRIPT_DIR}}"

# --- Argument Parsing ---
# Usage patterns:
#   ./cobalt-docker.sh                      # build + run (no profile)
#   ./cobalt-docker.sh custom.profile       # build + run with custom profile
#   ./cobalt-docker.sh lint custom.profile  # build + lint only
#   ./cobalt-docker.sh custom.profile --lint# build + lint + run

PROFILE_NAME=""
DO_LINT=false
LINT_ONLY=false
REST_API_USER=""
REST_API_PUBLISH_PORT=""
REST_API_PUBLISH_BIND="${REST_API_PUBLISH_BIND:-}"
COBALT_LISTENER_BIND_HOST="${COBALT_LISTENER_BIND_HOST:-}"
TEAMSERVER_HOST_OVERRIDE="${TEAMSERVER_HOST_OVERRIDE:-}"
SKIP_REST_API=""
SERVICE_BIND_HOST=""
SERVICE_PORT=""
UPSTREAM_HOST=""
UPSTREAM_PORT=""
HEALTHCHECK_URL=""
HEALTHCHECK_INSECURE=""
COBALTSTRIKE_LICENSE=""
TEAMSERVER_PASSWORD=""
USE_BIND_MOUNT=false
DOCKER_MOUNT_ARGS=()
PROFILE_CONTAINER_PATH=""
MOUNT_MODE="none"
PROFILE_SOURCE="none (no profile selected)"

DO_TOKEN=false
DO_STATUS=false
DO_STOP=false
DO_HELP=false

show_help() {
    echo ""
    echo "Usage: ./cobalt-docker.sh [command] [options]"
    echo ""
    echo "Commands:"
    echo "  (none)                Deploy the team server (runs setup wizard if needed)"
    echo "  <profile>             Deploy with a Malleable C2 profile (auto-linted)"
    echo "  api-token             Get a REST API bearer token from a running server"
    echo "  status                Check if the container is running"
    echo "  stop                  Stop and remove the container"
    echo "  lint <profile>        Lint a Malleable C2 profile without deploying"
    echo "  help                  Show this help message"
    echo ""
    echo "Examples:"
    echo "  ./cobalt-docker.sh                      # deploy with setup wizard"
    echo "  ./cobalt-docker.sh custom.profile        # lint + deploy with profile"
    echo "  ./cobalt-docker.sh api-token             # get bearer token"
    echo "  ./cobalt-docker.sh status                # check if running"
    echo "  ./cobalt-docker.sh stop                  # stop the server"
    echo "  ./cobalt-docker.sh lint custom.profile   # lint only (no deploy)"
    echo ""
}

while [[ $# -gt 0 ]]; do
    case "$1" in
        --token|token|--api-token|api-token)
            DO_TOKEN=true
            shift
            ;;
        --status|status)
            DO_STATUS=true
            shift
            ;;
        --stop|stop)
            DO_STOP=true
            shift
            ;;
        --help|help|-h)
            DO_HELP=true
            shift
            ;;
        --lint)
            DO_LINT=true
            shift
            ;;
        lint)
            DO_LINT=true
            LINT_ONLY=true
            shift
            ;;
        *)
            PROFILE_NAME="$1"
            shift
            ;;
    esac
done

if [ "$DO_HELP" = true ]; then
    show_help
    exit 0
fi

# Handle quick commands that don't need full config
if [ "$DO_STOP" = true ]; then
    # Load container name from .env
    if [ -f "$CONFIG_FILE" ]; then
        DOCKER_CONTAINER_NAME="$(get_env_value "CONTAINER_NAME" 2>/dev/null || echo "cobaltstrike-server")"
    else
        DOCKER_CONTAINER_NAME="cobaltstrike-server"
    fi

    echo "==> Stopping $DOCKER_CONTAINER_NAME..."

    # Remove from Tailscale if connected
    if docker ps -q -f "name=$DOCKER_CONTAINER_NAME" | grep -q .; then
        docker exec "$DOCKER_CONTAINER_NAME" tailscale logout 2>/dev/null && echo "==> Removed from Tailnet." || true
    fi

    docker stop "$DOCKER_CONTAINER_NAME" 2>/dev/null && echo "==> Stopped." || echo "==> Container not running."
    docker rm "$DOCKER_CONTAINER_NAME" 2>/dev/null || true
    exit 0
fi

if [ "$DO_STATUS" = true ]; then
    if [ -f "$CONFIG_FILE" ]; then
        DOCKER_CONTAINER_NAME="$(get_env_value "CONTAINER_NAME" 2>/dev/null || echo "cobaltstrike-server")"
    else
        DOCKER_CONTAINER_NAME="cobaltstrike-server"
    fi

    if docker ps -q -f "name=$DOCKER_CONTAINER_NAME" | grep -q .; then
        echo "==> $DOCKER_CONTAINER_NAME is running"
        docker ps -f "name=$DOCKER_CONTAINER_NAME" --format "  Started: {{.RunningFor}}\n  Ports: {{.Ports}}"
    else
        echo "==> $DOCKER_CONTAINER_NAME is not running"
    fi
    exit 0
fi

if [ "$DO_TOKEN" = true ]; then
    if ! docker ps -q -f "name=$DOCKER_CONTAINER_NAME" | grep -q .; then
        echo "Error: $DOCKER_CONTAINER_NAME is not running." >&2
        exit 1
    fi

    if [ ! -f "$CONFIG_FILE" ]; then
        echo "Error: $CONFIG_FILE not found — cannot read credentials." >&2
        exit 1
    fi

    TOKEN_USER="$(get_env_value "REST_API_USER" 2>/dev/null || echo "csrestapi")"
    TOKEN_PASS="$(get_env_value "TEAMSERVER_PASSWORD" 2>/dev/null || true)"
    TOKEN_PORT="$(get_env_value "REST_API_PUBLISH_PORT" 2>/dev/null || echo "50443")"

    if [ -z "$TOKEN_PASS" ]; then
        echo "Error: TEAMSERVER_PASSWORD not found in $CONFIG_FILE" >&2
        exit 1
    fi

    TOKEN_JSON="$(curl -sk -X POST "https://127.0.0.1:${TOKEN_PORT}/api/auth/login" \
        -H "Content-Type: application/json" \
        -d "{\"username\":\"${TOKEN_USER}\",\"password\":\"${TOKEN_PASS}\",\"duration_ms\":86400000}" 2>/dev/null || true)"

    ACCESS_TOKEN="$(printf '%s' "$TOKEN_JSON" | grep -o '"access_token":"[^"]*"' | sed 's/"access_token":"//;s/"$//' || true)"

    if [ -n "$ACCESS_TOKEN" ]; then
        echo ""
        echo "╔══════════════════════════════════════════════════════════════╗"
        echo "║  REST API Bearer Token                                      ║"
        echo "╠══════════════════════════════════════════════════════════════╣"
        printf '║  %s\n' "$ACCESS_TOKEN"
        echo "║                                                              ║"
        echo "║  Examples:                                                   ║"
        echo "║                                                              ║"
        echo "║  # List beacons                                              ║"
        printf '║  curl -sk -H "Authorization: Bearer <token>" \\\n'
        printf '║    https://127.0.0.1:%s/api/v1/beacons\n' "$TOKEN_PORT"
        echo "║                                                              ║"
        echo "║  # Health check                                              ║"
        printf '║  curl -sk https://127.0.0.1:%s/health\n' "$TOKEN_PORT"
        echo "║                                                              ║"
        echo "║  # OpenAPI docs (full endpoint list)                         ║"
        printf '║  curl -sk https://127.0.0.1:%s/v3/api-docs | python3 -m json.tool\n' "$TOKEN_PORT"
        echo "╚══════════════════════════════════════════════════════════════╝"
        echo ""
    else
        echo "Error: Could not retrieve bearer token." >&2
        if [ -n "$TOKEN_JSON" ]; then
            echo "Response: $TOKEN_JSON" >&2
        fi
        exit 1
    fi
    exit 0
fi

prompt_value() {
    local prompt_text="$1"
    local default_value="${2:-}"
    local is_secret="${3:-false}"
    local value=""

    if [ -n "$default_value" ]; then
        printf '%s [%s]: ' "$prompt_text" "$default_value" >&2
    else
        printf '%s: ' "$prompt_text" >&2
    fi

    if [ "$is_secret" = "true" ]; then
        read -rs value
        printf '\n' >&2
    else
        read -r value
    fi

    if [ -z "$value" ]; then
        value="$default_value"
    fi

    printf '%s' "$value"
}

write_env_value() {
    local key="$1"
    local value="$2"
    local config="$3"

    if grep -q "^[[:space:]]*${key}=" "$config" 2>/dev/null; then
        # Update existing key in place
        sed -i.bak "s|^[[:space:]]*${key}=.*|${key}=\"${value}\"|" "$config"
        rm -f "${config}.bak"
    else
        # Append new key
        printf '%s="%s"\n' "$key" "$value" >> "$config"
    fi
}

run_setup_wizard() {
    echo ""
    echo "╔══════════════════════════════════════════════════╗"
    echo "║         Cobalt Strike Docker — Setup             ║"
    echo "╚══════════════════════════════════════════════════╝"
    echo ""

    # Ensure .env exists (copy from template if needed)
    if [ ! -f "$CONFIG_FILE" ]; then
        if [ -f "$SCRIPT_DIR/.env.example" ]; then
            cp "$SCRIPT_DIR/.env.example" "$CONFIG_FILE"
        else
            touch "$CONFIG_FILE"
        fi
    fi

    # Read current values (may be placeholders)
    local current_license current_password current_ts_authkey current_ts_extra
    current_license="$(get_env_value "COBALTSTRIKE_LICENSE" 2>/dev/null || true)"
    current_password="$(get_env_value "TEAMSERVER_PASSWORD" 2>/dev/null || true)"
    current_ts_authkey="$(get_env_value "TS_AUTHKEY" 2>/dev/null || true)"
    current_ts_extra="$(get_env_value "TS_EXTRA_ARGS" 2>/dev/null || true)"

    # Clear placeholder values so they don't show as defaults
    case "$current_license" in
        *replace*|*REPLACE*|"") current_license="" ;;
    esac
    case "$current_password" in
        *replace*|*REPLACE*|"") current_password="" ;;
    esac

    # Prompt for required values
    local license password ts_authkey hostname profile_path

    if [ -z "$current_license" ]; then
        license="$(prompt_value "Cobalt Strike license key")"
        while [ -z "$license" ]; do
            echo "  License key is required." >&2
            license="$(prompt_value "Cobalt Strike license key")"
        done
    else
        license="$current_license"
        echo "  Cobalt Strike license: [already set]"
    fi

    if [ -z "$current_password" ]; then
        password="$(prompt_value "Team server password")"
        while [ -z "$password" ]; do
            echo "  Password is required." >&2
            password="$(prompt_value "Team server password")"
        done
    else
        password="$current_password"
        echo "  Team server password: [already set]"
    fi

    echo ""
    local container_name
    container_name="$(prompt_value "Container name" "cobalt-strike-server")"
    write_env_value "CONTAINER_NAME" "$container_name" "$CONFIG_FILE"
    DOCKER_CONTAINER_NAME="$container_name"

    echo ""
    echo "  Tailscale (optional — press Enter to skip)"
    ts_authkey="$(prompt_value "  Tailscale auth key" "${current_ts_authkey}")"

    if [ -n "$ts_authkey" ]; then
        write_env_value "TS_AUTHKEY" "$ts_authkey" "$CONFIG_FILE"
        write_env_value "TS_EXTRA_ARGS" "--hostname=${container_name}" "$CONFIG_FILE"
        write_env_value "TS_USERSPACE" "true" "$CONFIG_FILE"
        write_env_value "USE_TAILSCALE_IP" "true" "$CONFIG_FILE"
    fi

    write_env_value "COBALTSTRIKE_LICENSE" "$license" "$CONFIG_FILE"
    write_env_value "TEAMSERVER_PASSWORD" "$password" "$CONFIG_FILE"

    # Display configuration summary
    echo ""
    echo "  ┌─────────────────────────────────────────────┐"
    printf '  │  Container name:      %-22s│\n' "$container_name"
    printf '  │  Cobalt Strike key:   %-22s│\n' "[set]"
    printf '  │  Teamserver password: %-22s│\n' "[set]"
    if [ -n "$ts_authkey" ]; then
        printf '  │  Tailscale:           %-22s│\n' "on ($container_name)"
    else
        printf '  │  Tailscale:           %-22s│\n' "off"
    fi
    printf '  │  REST API:            %-22s│\n' "on"
    if [ -n "$PROFILE_NAME" ]; then
        printf '  │  Malleable profile:   %-22s│\n' "$PROFILE_NAME"
    else
        printf '  │  Malleable profile:   %-22s│\n' "default"
    fi
    echo "  └─────────────────────────────────────────────┘"
    echo ""
    echo "  Configuration saved to $CONFIG_FILE"
    echo ""
}

is_env_ready() {
    if [ ! -f "$CONFIG_FILE" ]; then
        return 1
    fi

    local license password
    license="$(get_env_value "COBALTSTRIKE_LICENSE" 2>/dev/null || true)"
    password="$(get_env_value "TEAMSERVER_PASSWORD" 2>/dev/null || true)"

    # Check for missing or placeholder values
    case "$license" in
        ""|*replace*|*REPLACE*) return 1 ;;
    esac
    case "$password" in
        ""|*replace*|*REPLACE*) return 1 ;;
    esac

    return 0
}

trim_whitespace() {
    local value="$1"
    value="${value#"${value%%[![:space:]]*}"}"
    value="${value%"${value##*[![:space:]]}"}"
    printf '%s' "$value"
}

strip_wrapping_quotes() {
    local value="$1"

    if [ "${#value}" -ge 2 ]; then
        if [[ "$value" == \"*\" && "$value" == *\" ]]; then
            value="${value:1:${#value}-2}"
        elif [[ "$value" == \'*\' && "$value" == *\' ]]; then
            value="${value:1:${#value}-2}"
        fi
    fi

    printf '%s' "$value"
}

get_env_value() {
    local key="$1"
    local raw_value=""

    raw_value="$(
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
                    print line
                    exit
                }
            }
        ' "$CONFIG_FILE"
    )"

    if [ -z "$raw_value" ]; then
        return 1
    fi

    raw_value="$(trim_whitespace "$raw_value")"
    raw_value="$(strip_wrapping_quotes "$raw_value")"
    printf '%s' "$raw_value"
}

warn() {
    printf 'Warning: %s\n' "$*" >&2
}

require_non_empty_config_value() {
    local key="$1"
    local value="$2"

    if [ -n "$value" ]; then
        return
    fi

    echo "Error: $key is missing or empty in $CONFIG_FILE"
    echo "Set $key in $CONFIG_FILE and re-run ./cobalt-docker.sh"
    exit 1
}

require_valid_port() {
    local key="$1"
    local value="$2"

    if [[ "$value" =~ ^[0-9]+$ ]] && [ "$value" -ge 1 ] && [ "$value" -le 65535 ]; then
        return
    fi

    echo "Error: $key must be an integer between 1 and 65535 in $CONFIG_FILE"
    exit 1
}

normalize_bool_setting() {
    local key="$1"
    local value="$2"
    local default_value="$3"

    if [ -z "$value" ]; then
        value="$default_value"
    fi

    value="$(printf '%s' "$value" | tr '[:upper:]' '[:lower:]')"

    case "$value" in
        true|false)
            printf '%s' "$value"
            ;;
        *)
            echo "Error: $key must be 'true' or 'false' in $CONFIG_FILE" >&2
            exit 1
            ;;
    esac
}

set_mount_selection() {
    MOUNT_MODE="$1"
    PROFILE_SOURCE="$2"
}

detect_linux_host_target() {
    local target=""

    target="$(hostname -I 2>/dev/null | awk '{print $1}')"

    if [ -z "$target" ] && command -v ip >/dev/null 2>&1; then
        target="$(ip route get 1.1.1.1 2>/dev/null | awk '
            /src/ {
                for (i = 1; i <= NF; i++) {
                    if ($i == "src") {
                        print $(i + 1)
                        exit
                    }
                }
            }
        ')"
    fi

    printf '%s' "$target"
}

detect_macos_host_target() {
    local target=""
    local default_iface=""

    if command -v route >/dev/null 2>&1; then
        default_iface="$(route -n get default 2>/dev/null | awk '/interface:/ { print $2; exit }')"
    fi

    if [ -n "$default_iface" ] && command -v ipconfig >/dev/null 2>&1; then
        target="$(ipconfig getifaddr "$default_iface" 2>/dev/null || true)"
    fi

    if [ -z "$target" ] && command -v ipconfig >/dev/null 2>&1; then
        for iface in en0 en1; do
            target="$(ipconfig getifaddr "$iface" 2>/dev/null || true)"
            if [ -n "$target" ]; then
                break
            fi
        done
    fi

    if [ -z "$target" ]; then
        target="$(ifconfig 2>/dev/null | awk '/inet / && $2 != "127.0.0.1" { print $2; exit }')"
    fi

    printf '%s' "$target"
}

detect_host_target() {
    local os_name="$1"
    local target=""

    if [ -n "$TEAMSERVER_HOST_OVERRIDE" ]; then
        printf '%s' "$TEAMSERVER_HOST_OVERRIDE"
        return 0
    fi

    case "$os_name" in
        Linux)
            target="$(detect_linux_host_target)"
            ;;
        Darwin)
            target="$(detect_macos_host_target)"
            ;;
        *)
            return 2
            ;;
    esac

    if [ -z "$target" ]; then
        return 1
    fi

    printf '%s' "$target"
}

docker_can_bind_mount_path() {
    local source_path="$1"

    docker run --rm \
      --platform "$DOCKER_PLATFORM" \
      --mount "type=bind,source=$source_path,target=/mnt,readonly" \
      --entrypoint /bin/sh \
      "$DOCKER_IMAGE_NAME":latest \
      -c 'true' >/dev/null 2>&1
}

image_has_file() {
    local file_path="$1"

    docker run --rm \
      --platform "$DOCKER_PLATFORM" \
      --entrypoint /bin/sh \
      "$DOCKER_IMAGE_NAME":latest \
      -c 'test -f "$1"' sh "$file_path" >/dev/null 2>&1
}

configure_mount_mode() {
    USE_BIND_MOUNT=false
    DOCKER_MOUNT_ARGS=()
    PROFILE_CONTAINER_PATH=""

    if [ -z "$PROFILE_NAME" ]; then
        if [ ! -d "$MOUNT_SOURCE" ]; then
            warn "Mount source path does not exist: $MOUNT_SOURCE"
            set_mount_selection "none" "none (no profile selected)"
            echo "==> Mount mode: $MOUNT_MODE"
            echo "==> Profile source: $PROFILE_SOURCE"
            return
        fi

        if docker_can_bind_mount_path "$MOUNT_SOURCE"; then
            USE_BIND_MOUNT=true
            DOCKER_MOUNT_ARGS=(--mount "type=bind,source=$MOUNT_SOURCE,target=$CONTAINER_MOUNT_TARGET")
            set_mount_selection "bind" "none (no profile selected; host mount enabled)"
            echo "==> Bind mount enabled: $MOUNT_SOURCE -> $CONTAINER_MOUNT_TARGET"
        else
            warn "Bind mount source is not daemon-visible for this Docker context: $MOUNT_SOURCE"
            set_mount_selection "none" "none (no profile selected)"
        fi

        echo "==> Mount mode: $MOUNT_MODE"
        echo "==> Profile source: $PROFILE_SOURCE"
        return
    fi

    PROFILE_CONTAINER_PATH="$CONTAINER_MOUNT_TARGET/$PROFILE_NAME"

    if [ -d "$MOUNT_SOURCE" ] && docker_can_bind_mount_path "$MOUNT_SOURCE"; then
        USE_BIND_MOUNT=true
        DOCKER_MOUNT_ARGS=(--mount "type=bind,source=$MOUNT_SOURCE,target=$CONTAINER_MOUNT_TARGET")

        if [ ! -f "$MOUNT_SOURCE/$PROFILE_NAME" ]; then
            echo "Error: Profile '$PROFILE_NAME' not found at mount source path: $MOUNT_SOURCE/$PROFILE_NAME"
            exit 1
        fi

        set_mount_selection "bind" "bind-mounted profile: $MOUNT_SOURCE/$PROFILE_NAME"
        echo "==> Bind mount enabled: $MOUNT_SOURCE -> $CONTAINER_MOUNT_TARGET"
        echo "==> Mount mode: $MOUNT_MODE"
        echo "==> Profile source: $PROFILE_SOURCE"
        return
    fi

    if [ ! -d "$MOUNT_SOURCE" ]; then
        warn "Mount source path does not exist: $MOUNT_SOURCE"
    else
        warn "Bind mount source is not daemon-visible for this Docker context: $MOUNT_SOURCE"
    fi
    warn "Falling back to in-image profiles (no host bind mount)."

    if ! image_has_file "$PROFILE_CONTAINER_PATH"; then
        echo "Error: Profile '$PROFILE_NAME' is unavailable in fallback mode."
        echo "Expected image path: $PROFILE_CONTAINER_PATH"
        echo "Use a baked-in profile, or set MOUNT_SOURCE/COBALT_DOCKER_MOUNT_SOURCE to a Docker-shared path (e.g. under \$HOME)."
        exit 1
    fi

    set_mount_selection "fallback" "in-image profile: $PROFILE_CONTAINER_PATH"
    echo "==> Fallback mode enabled (USE_BIND_MOUNT=false). Using in-image profile: $PROFILE_CONTAINER_PATH"
    echo "==> Mount mode: $MOUNT_MODE"
    echo "==> Profile source: $PROFILE_SOURCE"
}

load_configuration() {
    if ! is_env_ready; then
        run_setup_wizard
    fi

    DOCKER_CONTAINER_NAME="$(get_env_value "CONTAINER_NAME" || echo "cobaltstrike-server")"
    COBALTSTRIKE_LICENSE="$(get_env_value "COBALTSTRIKE_LICENSE" || true)"
    TEAMSERVER_PASSWORD="$(get_env_value "TEAMSERVER_PASSWORD" || true)"
    REST_API_USER="$(get_env_value "REST_API_USER" || true)"
    REST_API_PUBLISH_PORT="$(get_env_value "REST_API_PUBLISH_PORT" || true)"
    REST_API_PUBLISH_BIND_FROM_FILE="$(get_env_value "REST_API_PUBLISH_BIND" || true)"
    SERVICE_BIND_HOST="$(get_env_value "SERVICE_BIND_HOST" || true)"
    SERVICE_PORT="$(get_env_value "SERVICE_PORT" || true)"
    UPSTREAM_HOST="$(get_env_value "UPSTREAM_HOST" || true)"
    UPSTREAM_PORT="$(get_env_value "UPSTREAM_PORT" || true)"
    HEALTHCHECK_URL="$(get_env_value "HEALTHCHECK_URL" || true)"
    HEALTHCHECK_INSECURE="$(get_env_value "HEALTHCHECK_INSECURE" || true)"
    TS_AUTHKEY="$(get_env_value "TS_AUTHKEY" || true)"
    TS_API_KEY="$(get_env_value "TS_API_KEY" || true)"
    TS_EXTRA_ARGS="$(get_env_value "TS_EXTRA_ARGS" || true)"
    TS_USERSPACE="$(get_env_value "TS_USERSPACE" || true)"
    USE_TAILSCALE_IP="$(get_env_value "USE_TAILSCALE_IP" || true)"
    SKIP_REST_API="$(get_env_value "SKIP_REST_API" || true)"
    TEAMSERVER_HOST_OVERRIDE_FROM_FILE="$(get_env_value "TEAMSERVER_HOST_OVERRIDE" || true)"
    COBALT_LISTENER_BIND_HOST_FROM_FILE="$(get_env_value "COBALT_LISTENER_BIND_HOST" || true)"

    require_non_empty_config_value "COBALTSTRIKE_LICENSE" "$COBALTSTRIKE_LICENSE"
    require_non_empty_config_value "TEAMSERVER_PASSWORD" "$TEAMSERVER_PASSWORD"

    if [ -z "$REST_API_USER" ]; then
        REST_API_USER="csrestapi"
    fi

    if [ -z "$REST_API_PUBLISH_PORT" ]; then
        REST_API_PUBLISH_PORT="50443"
    fi

    require_valid_port "REST_API_PUBLISH_PORT" "$REST_API_PUBLISH_PORT"

    if [ -z "$REST_API_PUBLISH_BIND" ]; then
        REST_API_PUBLISH_BIND="$REST_API_PUBLISH_BIND_FROM_FILE"
    fi

    if [ -z "$REST_API_PUBLISH_BIND" ]; then
        REST_API_PUBLISH_BIND="127.0.0.1"
    fi

    if [[ "$REST_API_PUBLISH_BIND" =~ [[:space:]] ]]; then
        echo "Error: REST_API_PUBLISH_BIND must not contain whitespace"
        exit 1
    fi

    if [ -z "$COBALT_LISTENER_BIND_HOST" ]; then
        COBALT_LISTENER_BIND_HOST="$COBALT_LISTENER_BIND_HOST_FROM_FILE"
    fi

    if [ -z "$COBALT_LISTENER_BIND_HOST" ]; then
        COBALT_LISTENER_BIND_HOST="0.0.0.0"
    fi

    if [ -z "$SERVICE_BIND_HOST" ]; then
        SERVICE_BIND_HOST="0.0.0.0"
    fi

    if [ -z "$SERVICE_PORT" ]; then
        SERVICE_PORT="50443"
    fi

    require_valid_port "SERVICE_PORT" "$SERVICE_PORT"

    if [ -z "$UPSTREAM_HOST" ]; then
        UPSTREAM_HOST="127.0.0.1"
    fi

    if [ -z "$UPSTREAM_PORT" ]; then
        UPSTREAM_PORT="50050"
    fi

    require_valid_port "UPSTREAM_PORT" "$UPSTREAM_PORT"
    HEALTHCHECK_INSECURE="$(normalize_bool_setting "HEALTHCHECK_INSECURE" "$HEALTHCHECK_INSECURE" "true")"
    TS_USERSPACE="$(normalize_bool_setting "TS_USERSPACE" "$TS_USERSPACE" "false")"
    USE_TAILSCALE_IP="$(normalize_bool_setting "USE_TAILSCALE_IP" "$USE_TAILSCALE_IP" "false")"
    SKIP_REST_API="$(normalize_bool_setting "SKIP_REST_API" "$SKIP_REST_API" "false")"

    if [ -z "$TEAMSERVER_HOST_OVERRIDE" ]; then
        TEAMSERVER_HOST_OVERRIDE="$TEAMSERVER_HOST_OVERRIDE_FROM_FILE"
    fi

    if [[ "$TEAMSERVER_HOST_OVERRIDE" =~ [[:space:]] ]]; then
        echo "Error: TEAMSERVER_HOST_OVERRIDE must not contain whitespace in $CONFIG_FILE"
        exit 1
    fi

    if [ -z "$HEALTHCHECK_URL" ]; then
        HEALTHCHECK_URL="https://127.0.0.1:${SERVICE_PORT}/health"
    fi
}

# --- Script Logic ---

# 1. Load configuration (required preflight).
echo "==> Loading configuration from $CONFIG_FILE..."
load_configuration

# Display status summary
echo ""
echo "  ┌─────────────────────────────────────────────┐"
printf '  │  Cobalt Strike key:  %-23s│\n' "[found]"
printf '  │  Teamserver password: %-22s│\n' "[found]"
if [ -n "${TS_AUTHKEY:-}" ]; then
    printf '  │  Tailscale:           %-22s│\n' "on"
else
    printf '  │  Tailscale:           %-22s│\n' "off"
fi
printf '  │  REST API:            %-22s│\n' "on"
if [ -n "$PROFILE_NAME" ]; then
    printf '  │  Malleable profile:   %-22s│\n' "$PROFILE_NAME"
else
    printf '  │  Malleable profile:   %-22s│\n' "default"
fi
printf '  │  Platform:            %-22s│\n' "$DOCKER_PLATFORM"
echo "  └─────────────────────────────────────────────┘"
echo ""

# 2. Build the Docker image.
echo "==> Building the Docker image ($DOCKER_IMAGE_NAME)..."
docker build --platform "$DOCKER_PLATFORM" --build-arg COBALTSTRIKE_LICENSE="$COBALTSTRIKE_LICENSE" -t "$DOCKER_IMAGE_NAME":latest "$SCRIPT_DIR"

# 3. Configure mount mode with daemon-visibility probe.
echo "==> Selected profile: $PROFILE_NAME"
echo "==> Mount source candidate: $MOUNT_SOURCE"
configure_mount_mode

# 4. Lint the profile with c2lint inside the Docker image.
if [ -n "$PROFILE_NAME" ]; then
    echo "==> Running c2lint against $PROFILE_NAME inside Docker image..."
    docker run --rm \
      --platform "$DOCKER_PLATFORM" \
      --entrypoint /bin/bash \
      ${DOCKER_MOUNT_ARGS[@]+"${DOCKER_MOUNT_ARGS[@]}"} \
      "$DOCKER_IMAGE_NAME":latest \
      -lc "cd /opt/cobaltstrike/server && ./c2lint $PROFILE_CONTAINER_PATH"

    if [ "$LINT_ONLY" = true ]; then
        echo "==> Lint-only mode complete. Not starting team server."
        exit 0
    fi
fi

# 5. Detect the operating system and get the host's primary IP address.
OS="$(uname)"
TEAMSERVER_HOST_TARGET="$(detect_host_target "$OS" || true)"

if [ -z "$TEAMSERVER_HOST_TARGET" ]; then
    if [[ "$OS" != "Linux" && "$OS" != "Darwin" ]]; then
        echo "Error: Unsupported OS for automatic host target detection: $OS"
    else
        echo "Error: Could not determine a host target for OS=$OS."
    fi
    echo "Set TEAMSERVER_HOST_OVERRIDE in $CONFIG_FILE (or environment) and re-run ./cobalt-docker.sh"
    exit 1
fi

if [ -n "$TEAMSERVER_HOST_OVERRIDE" ]; then
    echo "==> Using TEAMSERVER_HOST_OVERRIDE: $TEAMSERVER_HOST_TARGET"
else
    echo "==> Detected host target ($OS): $TEAMSERVER_HOST_TARGET"
fi
echo "==> REST API will be published at: https://$REST_API_PUBLISH_BIND:$REST_API_PUBLISH_PORT"

# 7. Conditionally add TUN device if present and Tailscale is enabled.
TUN_DEVICE_ARGS=()
if [ -n "$TS_AUTHKEY" ]; then
    if [ -c /dev/net/tun ]; then
        TUN_DEVICE_ARGS=(--device /dev/net/tun:/dev/net/tun)
    else
        warn "/dev/net/tun not found. Tailscale will fall back to userspace mode if TS_USERSPACE is true."
    fi
fi

# 8. Run the Docker container (detached).
echo "==> Starting Cobalt Strike Docker container ($DOCKER_CONTAINER_NAME)..."
docker rm -f "$DOCKER_CONTAINER_NAME" >/dev/null 2>&1 || true
docker run -d --name "$DOCKER_CONTAINER_NAME" \
  --platform "$DOCKER_PLATFORM" \
  --restart unless-stopped \
  ${DOCKER_MOUNT_ARGS[@]+"${DOCKER_MOUNT_ARGS[@]}"} \
  ${TUN_DEVICE_ARGS[@]+"${TUN_DEVICE_ARGS[@]}"} \
  -e "REST_API_USER=$REST_API_USER" \
  -e "SERVICE_BIND_HOST=$SERVICE_BIND_HOST" \
  -e "SERVICE_PORT=$SERVICE_PORT" \
  -e "UPSTREAM_HOST=$UPSTREAM_HOST" \
  -e "UPSTREAM_PORT=$UPSTREAM_PORT" \
  -e "HEALTHCHECK_URL=$HEALTHCHECK_URL" \
  -e "HEALTHCHECK_INSECURE=$HEALTHCHECK_INSECURE" \
  -e "TS_AUTHKEY=$TS_AUTHKEY" \
  -e "TS_API_KEY=$TS_API_KEY" \
  -e "TS_EXTRA_ARGS=$TS_EXTRA_ARGS" \
  -e "TS_USERSPACE=$TS_USERSPACE" \
  -e "USE_TAILSCALE_IP=$USE_TAILSCALE_IP" \
  -e "SKIP_REST_API=$SKIP_REST_API" \
  --cap-add=NET_ADMIN \
  -p 50050:50050 \
  -p "$COBALT_LISTENER_BIND_HOST:80:80" \
  -p "$COBALT_LISTENER_BIND_HOST:443:443" \
  -p "$COBALT_LISTENER_BIND_HOST:53:53/udp" \
  -p "$REST_API_PUBLISH_BIND:$REST_API_PUBLISH_PORT:$SERVICE_PORT" \
  "$DOCKER_IMAGE_NAME":latest \
  "$TEAMSERVER_HOST_TARGET" \
  "$TEAMSERVER_PASSWORD" \
  ${PROFILE_CONTAINER_PATH:+"$PROFILE_CONTAINER_PATH"} >/dev/null

echo "==> Container started in background. Waiting for startup..."

# 9. Follow logs and wait for startup to complete, then display status and exit.
STARTUP_TIMEOUT=120
BEARER_TOKEN=""

for i in $(seq 1 "$STARTUP_TIMEOUT"); do
    # Check if container is still running
    if ! docker ps -q -f "name=$DOCKER_CONTAINER_NAME" | grep -q .; then
        echo ""
        echo "Error: Container exited unexpectedly. Check logs:"
        echo "  docker logs $DOCKER_CONTAINER_NAME"
        exit 1
    fi

    LOGS="$(docker logs "$DOCKER_CONTAINER_NAME" 2>&1)"

    # Check for fatal errors
    if printf '%s' "$LOGS" | grep -q 'STARTUP\[.*\] ERROR'; then
        echo ""
        printf '%s' "$LOGS" | grep 'STARTUP\[.*\] ERROR'
        echo ""
        echo "Check full logs: docker logs $DOCKER_CONTAINER_NAME"
        exit 1
    fi

    # Check if monitor phase reached (startup complete)
    if printf '%s' "$LOGS" | grep -q 'STARTUP\[monitor\]'; then
        # Try to extract bearer token
        BEARER_TOKEN="$(printf '%s' "$LOGS" | grep -o '"access_token":"[^"]*"' | sed 's/"access_token":"//;s/"$//' | head -1 || true)"
        break
    fi

    # Check if rest-token phase reached (token displayed even if monitor hasn't logged yet)
    if printf '%s' "$LOGS" | grep -q 'STARTUP\[rest-token\].*bearer token acquired'; then
        BEARER_TOKEN="$(printf '%s' "$LOGS" | grep -o '"access_token":"[^"]*"' | sed 's/"access_token":"//;s/"$//' | head -1 || true)"
        break
    fi

    sleep 1
done

echo ""
echo "╔══════════════════════════════════════════════════════════════╗"
echo "║  Cobalt Strike Docker — Running                              ║"
echo "╠══════════════════════════════════════════════════════════════╣"
printf '║  Container:  %-47s║\n' "$DOCKER_CONTAINER_NAME"
printf '║  Teamserver: %-47s║\n' "https://$TEAMSERVER_HOST_TARGET:50050"
printf '║  REST API:   %-47s║\n' "https://$REST_API_PUBLISH_BIND:$REST_API_PUBLISH_PORT"
if [ -n "$BEARER_TOKEN" ]; then
    echo "║                                                              ║"
    echo "║  Bearer Token:                                               ║"
    printf '║  %s\n' "$BEARER_TOKEN"
fi
echo "║                                                              ║"
echo "║  Commands:                                                   ║"
echo "║    docker logs -f cobaltstrike_server   # follow logs        ║"
echo "║    docker stop cobaltstrike_server      # stop server        ║"
echo "╚══════════════════════════════════════════════════════════════╝"
echo ""
