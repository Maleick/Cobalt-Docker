#!/bin/bash

#
# This script builds and runs the Cobalt Strike Docker container.
#

set -euo pipefail

# --- Configuration ---
# Name for the Docker image and container
DOCKER_IMAGE_NAME="cobaltstrike"
DOCKER_CONTAINER_NAME="cobaltstrike_server"
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
TEAMSERVER_HOST_OVERRIDE="${TEAMSERVER_HOST_OVERRIDE:-}"
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

while [[ $# -gt 0 ]]; do
    case "$1" in
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
    if [ ! -f "$CONFIG_FILE" ]; then
        echo "Error: Required configuration file not found: $CONFIG_FILE"
        echo "Create $CONFIG_FILE from $SCRIPT_DIR/.env.example and populate:"
        echo "  - COBALTSTRIKE_LICENSE"
        echo "  - TEAMSERVER_PASSWORD"
        exit 1
    fi

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
    TEAMSERVER_HOST_OVERRIDE_FROM_FILE="$(get_env_value "TEAMSERVER_HOST_OVERRIDE" || true)"

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
# Never print secret values in startup logs.
echo "==> Configuration loaded. REST API user: $REST_API_USER, host publish port: $REST_API_PUBLISH_PORT, platform: $DOCKER_PLATFORM"
echo "==> Startup controls: SERVICE_BIND_HOST=$SERVICE_BIND_HOST SERVICE_PORT=$SERVICE_PORT UPSTREAM_HOST=$UPSTREAM_HOST UPSTREAM_PORT=$UPSTREAM_PORT HEALTHCHECK_INSECURE=$HEALTHCHECK_INSECURE"
echo "==> Runtime toggles: TS_USERSPACE=$TS_USERSPACE USE_TAILSCALE_IP=$USE_TAILSCALE_IP"
echo "==> Healthcheck URL: $HEALTHCHECK_URL"

# 2. Build the Docker image.
echo "==> Building the Docker image ($DOCKER_IMAGE_NAME)..."
docker build --platform "$DOCKER_PLATFORM" --build-arg COBALTSTRIKE_LICENSE="$COBALTSTRIKE_LICENSE" -t "$DOCKER_IMAGE_NAME":latest "$SCRIPT_DIR"

# 3. Configure mount mode with daemon-visibility probe.
echo "==> Selected profile: $PROFILE_NAME"
echo "==> Mount source candidate: $MOUNT_SOURCE"
configure_mount_mode

# 4. Optionally lint the profile with c2lint inside the Docker image.
if [ "$DO_LINT" = true ] && [ -n "$PROFILE_NAME" ]; then
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

# 8. Run the Docker container.
echo "==> Starting Cobalt Strike Docker container ($DOCKER_CONTAINER_NAME)..."
docker rm -f "$DOCKER_CONTAINER_NAME" >/dev/null 2>&1 || true
docker run --name "$DOCKER_CONTAINER_NAME" \
  --platform "$DOCKER_PLATFORM" \
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
  --cap-add=NET_ADMIN \
  -p 50050:50050 \
  -p 80:80 \
  -p 443:443 \
  -p 53:53/udp \
  -p "$REST_API_PUBLISH_BIND:$REST_API_PUBLISH_PORT:$SERVICE_PORT" \
  --rm \
  "$DOCKER_IMAGE_NAME":latest \
  "$TEAMSERVER_HOST_TARGET" \
  "$TEAMSERVER_PASSWORD" \
  ${PROFILE_CONTAINER_PATH:+"$PROFILE_CONTAINER_PATH"}
