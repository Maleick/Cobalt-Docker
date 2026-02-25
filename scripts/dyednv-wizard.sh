#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
ENV_FILE="$ROOT_DIR/.env"
ENV_EXAMPLE_FILE="$ROOT_DIR/.env.example"
OUTPUT_BASE_DIR="$ROOT_DIR/configs/dyednv"

CONFIG_SOURCE=""
if [ -f "$ENV_FILE" ]; then
    CONFIG_SOURCE="$ENV_FILE"
elif [ -f "$ENV_EXAMPLE_FILE" ]; then
    CONFIG_SOURCE="$ENV_EXAMPLE_FILE"
fi

if [ -z "$CONFIG_SOURCE" ]; then
    echo "Error: no .env or .env.example file found in $ROOT_DIR"
    exit 1
fi

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

    raw_value="$({
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
        ' "$CONFIG_SOURCE"
    } 2>/dev/null || true)"

    if [ -z "$raw_value" ]; then
        return 1
    fi

    raw_value="$(trim_whitespace "$raw_value")"
    raw_value="$(strip_wrapping_quotes "$raw_value")"
    printf '%s' "$raw_value"
}

normalize_bool_or_default() {
    local value="$1"
    local fallback="$2"

    if [ -z "$value" ]; then
        printf '%s' "$fallback"
        return
    fi

    value="$(printf '%s' "$value" | tr '[:upper:]' '[:lower:]')"
    case "$value" in
        true|false)
            printf '%s' "$value"
            ;;
        *)
            printf '%s' "$fallback"
            ;;
    esac
}

json_escape() {
    local value="$1"
    value="${value//\\/\\\\}"
    value="${value//\"/\\\"}"
    value="${value//$'\n'/\\n}"
    value="${value//$'\r'/\\r}"
    value="${value//$'\t'/\\t}"
    printf '%s' "$value"
}

slugify() {
    local raw="$1"
    local slug
    slug="$(printf '%s' "$raw" | tr '[:upper:]' '[:lower:]' | sed -E 's/[^a-z0-9]+/-/g; s/^-+//; s/-+$//; s/-{2,}/-/g')"
    if [ -z "$slug" ]; then
        slug="dyednv"
    fi
    printf '%s' "$slug"
}

validate_required() {
    [ -n "$1" ]
}

validate_slug_name() {
    [[ "$1" =~ ^[a-z0-9]+([a-z0-9-]*[a-z0-9])?$ ]]
}

validate_simple_token() {
    [[ "$1" =~ ^[A-Za-z0-9._-]+$ ]]
}

validate_port() {
    [[ "$1" =~ ^[0-9]+$ ]] && [ "$1" -ge 1 ] && [ "$1" -le 65535 ]
}

validate_bool() {
    [[ "$1" == "true" || "$1" == "false" ]]
}

validate_secret_ref() {
    [[ "$1" =~ ^[A-Za-z][A-Za-z0-9+.-]*://.+$ ]]
}

reject_probable_raw_secret() {
    local value="$1"
    local lowered

    if [[ "$value" =~ ^[A-Za-z][A-Za-z0-9+.-]*:// ]]; then
        return 0
    fi

    lowered="$(printf '%s' "$value" | tr '[:upper:]' '[:lower:]')"

    case "$lowered" in
        *"-----begin"*"private key"*|tskey-*|sk-*|ghp_*|gho_*|glpat-*|akia*)
            return 1
            ;;
        *)
            return 0
            ;;
    esac
}

prompt_value() {
    local prompt_label="$1"
    local default_value="$2"
    local required="$3"
    local validator_fn="$4"
    local validator_message="$5"
    local value=""

    while true; do
        if [ -n "$default_value" ]; then
            printf '%s [%s]: ' "$prompt_label" "$default_value" >&2
        else
            printf '%s: ' "$prompt_label" >&2
        fi

        if ! IFS= read -r value; then
            echo >&2
            echo "Input stream ended before completion." >&2
            exit 1
        fi

        if [ -z "$value" ]; then
            value="$default_value"
        fi

        if [ "$required" = "true" ] && ! validate_required "$value"; then
            echo "Error: value is required." >&2
            continue
        fi

        if [ -n "$value" ] && [ -n "$validator_fn" ] && ! "$validator_fn" "$value"; then
            echo "Error: $validator_message" >&2
            continue
        fi

        printf '%s\n' "$value"
        return 0
    done
}

prompt_bool() {
    local prompt_label="$1"
    local default_value="$2"
    local value=""

    while true; do
        value="$(prompt_value "$prompt_label" "$default_value" "true" "validate_bool" "value must be 'true' or 'false'.")"
        value="$(printf '%s' "$value" | tr '[:upper:]' '[:lower:]')"
        if validate_bool "$value"; then
            printf '%s\n' "$value"
            return 0
        fi
        echo "Error: value must be 'true' or 'false'." >&2
    done
}

prompt_secret_ref() {
    local prompt_label="$1"
    local default_value="$2"
    local required="$3"
    local value=""

    while true; do
        value="$(prompt_value "$prompt_label" "$default_value" "$required" "" "")"

        if [ -z "$value" ] && [ "$required" = "false" ]; then
            printf '%s\n' ""
            return 0
        fi

        if ! reject_probable_raw_secret "$value"; then
            echo "Error: value looks like a raw secret. Store only secret references." >&2
            continue
        fi

        if ! validate_secret_ref "$value"; then
            echo "Error: secret reference must use scheme://value format." >&2
            continue
        fi

        printf '%s\n' "$value"
        return 0
    done
}

prompt_yes_no() {
    local prompt_label="$1"
    local default_value="$2"
    local value=""

    while true; do
        if [ "$default_value" = "yes" ]; then
            printf '%s [Y/n]: ' "$prompt_label" >&2
        else
            printf '%s [y/N]: ' "$prompt_label" >&2
        fi

        if ! IFS= read -r value; then
            echo >&2
            echo "Input stream ended before completion." >&2
            exit 1
        fi

        value="$(trim_whitespace "$value")"
        value="$(printf '%s' "$value" | tr '[:upper:]' '[:lower:]')"

        if [ -z "$value" ]; then
            value="$default_value"
        fi

        case "$value" in
            y|yes)
                printf '%s\n' "yes"
                return 0
                ;;
            n|no)
                printf '%s\n' "no"
                return 0
                ;;
            *)
                echo "Error: enter yes or no." >&2
                ;;
        esac
    done
}

printf '\nDyeDNV v1 Wizard\n'
printf 'Config defaults source: %s\n\n' "$CONFIG_SOURCE"

rest_api_user_default="$(get_env_value "REST_API_USER" || true)"
rest_api_publish_bind_default="$(get_env_value "REST_API_PUBLISH_BIND" || true)"
rest_api_publish_port_default="$(get_env_value "REST_API_PUBLISH_PORT" || true)"
service_bind_host_default="$(get_env_value "SERVICE_BIND_HOST" || true)"
service_port_default="$(get_env_value "SERVICE_PORT" || true)"
upstream_host_default="$(get_env_value "UPSTREAM_HOST" || true)"
upstream_port_default="$(get_env_value "UPSTREAM_PORT" || true)"
healthcheck_url_default="$(get_env_value "HEALTHCHECK_URL" || true)"
healthcheck_insecure_default="$(get_env_value "HEALTHCHECK_INSECURE" || true)"
teamserver_host_override_default="$(get_env_value "TEAMSERVER_HOST_OVERRIDE" || true)"
ts_userspace_default="$(get_env_value "TS_USERSPACE" || true)"
use_tailscale_ip_default="$(get_env_value "USE_TAILSCALE_IP" || true)"
ts_extra_args_default="$(get_env_value "TS_EXTRA_ARGS" || true)"
ts_authkey_value="$(get_env_value "TS_AUTHKEY" || true)"

docker_platform_default="${DOCKER_PLATFORM:-linux/amd64}"
mount_source_default="${MOUNT_SOURCE:-$ROOT_DIR}"

rest_api_user_default="${rest_api_user_default:-csrestapi}"
rest_api_publish_bind_default="${rest_api_publish_bind_default:-127.0.0.1}"
rest_api_publish_port_default="${rest_api_publish_port_default:-50443}"
service_bind_host_default="${service_bind_host_default:-0.0.0.0}"
service_port_default="${service_port_default:-50443}"
upstream_host_default="${upstream_host_default:-127.0.0.1}"
upstream_port_default="${upstream_port_default:-50050}"
healthcheck_insecure_default="$(normalize_bool_or_default "$healthcheck_insecure_default" "true")"
ts_userspace_default="$(normalize_bool_or_default "$ts_userspace_default" "false")"
use_tailscale_ip_default="$(normalize_bool_or_default "$use_tailscale_ip_default" "false")"

if [ -z "$healthcheck_url_default" ]; then
    healthcheck_url_default="https://127.0.0.1:${service_port_default}/health"
fi

tailscale_enabled_default="false"
if [ -n "$ts_authkey_value" ]; then
    tailscale_enabled_default="true"
fi

default_name="cobalt-docker-prod"
default_environment="prod"
default_owner="${USER:-operator}"

printf '1) Metadata\n'
name="$(prompt_value "metadata.name (slug-safe)" "$default_name" "true" "validate_slug_name" "name must match ^[a-z0-9]+([a-z0-9-]*[a-z0-9])?$.")"
environment="$(prompt_value "metadata.environment" "$default_environment" "true" "validate_simple_token" "environment must use letters, numbers, dot, underscore, or dash.")"
owner="$(prompt_value "metadata.owner" "$default_owner" "true" "" "")"
created_at_utc="$(date -u +"%Y-%m-%dT%H:%M:%SZ")"

printf '\n2) Teamserver/Profile Metadata\n'
external_host_default="${teamserver_host_override_default:-127.0.0.1}"
external_host="$(prompt_value "teamserver.external_host" "$external_host_default" "true" "validate_required" "external_host is required.")"
profile_name="$(prompt_value "teamserver.profile_name (optional)" "" "false" "" "")"
profile_intent="$(prompt_value "teamserver.profile_intent" "default-runtime-profile" "true" "validate_required" "profile_intent is required.")"

printf '\n3) Runtime\n'
docker_platform="$(prompt_value "runtime.docker_platform" "$docker_platform_default" "true" "validate_required" "docker_platform is required.")"
mount_source="$(prompt_value "runtime.mount_source" "$mount_source_default" "true" "validate_required" "mount_source is required.")"
teamserver_host_override="$(prompt_value "runtime.teamserver_host_override (optional)" "$teamserver_host_override_default" "false" "" "")"

printf '\n4) REST API\n'
rest_api_user="$(prompt_value "rest_api.rest_api_user" "$rest_api_user_default" "true" "validate_required" "rest_api_user is required.")"
publish_bind="$(prompt_value "rest_api.publish_bind" "$rest_api_publish_bind_default" "true" "validate_required" "publish_bind is required.")"
publish_port="$(prompt_value "rest_api.publish_port" "$rest_api_publish_port_default" "true" "validate_port" "value must be an integer between 1 and 65535.")"
service_bind_host="$(prompt_value "rest_api.service_bind_host" "$service_bind_host_default" "true" "validate_required" "service_bind_host is required.")"
service_port="$(prompt_value "rest_api.service_port" "$service_port_default" "true" "validate_port" "value must be an integer between 1 and 65535.")"
upstream_host="$(prompt_value "rest_api.upstream_host" "$upstream_host_default" "true" "validate_required" "upstream_host is required.")"
upstream_port="$(prompt_value "rest_api.upstream_port" "$upstream_port_default" "true" "validate_port" "value must be an integer between 1 and 65535.")"
healthcheck_url="$(prompt_value "rest_api.healthcheck_url" "$healthcheck_url_default" "true" "validate_required" "healthcheck_url is required.")"
healthcheck_insecure="$(prompt_bool "rest_api.healthcheck_insecure" "$healthcheck_insecure_default")"

printf '\n5) Tailscale\n'
tailscale_enabled="$(prompt_bool "tailscale.enabled" "$tailscale_enabled_default")"
ts_userspace="$(prompt_bool "tailscale.ts_userspace" "$ts_userspace_default")"
use_tailscale_ip="$(prompt_bool "tailscale.use_tailscale_ip" "$use_tailscale_ip_default")"
ts_extra_args="$(prompt_value "tailscale.ts_extra_args (optional)" "$ts_extra_args_default" "false" "" "")"

printf '\n6) Secret References\n'
cobaltstrike_license_ref="$(prompt_secret_ref "secret_refs.cobaltstrike_license_ref" "secret://cobaltstrike/license" "true")"
teamserver_password_ref="$(prompt_secret_ref "secret_refs.teamserver_password_ref" "secret://teamserver/password" "true")"

ts_authkey_ref=""
ts_api_key_ref=""
if [ "$tailscale_enabled" = "true" ]; then
    ts_authkey_ref="$(prompt_secret_ref "secret_refs.ts_authkey_ref (optional)" "secret://tailscale/authkey" "false")"
    ts_api_key_ref="$(prompt_secret_ref "secret_refs.ts_api_key_ref (optional)" "secret://tailscale/api-key" "false")"
fi

slug_name="$(slugify "$name")"
default_output_path="$OUTPUT_BASE_DIR/${slug_name}.dyednv.json"

printf '\n7) Output\n'
output_path="$(prompt_value "Output file path" "$default_output_path" "true" "validate_required" "output path is required.")"
if [[ "$output_path" != /* ]]; then
    output_path="$ROOT_DIR/$output_path"
fi

printf '\nSummary\n'
printf '  metadata.name: %s\n' "$name"
printf '  metadata.environment: %s\n' "$environment"
printf '  metadata.owner: %s\n' "$owner"
printf '  teamserver.external_host: %s\n' "$external_host"
printf '  runtime.docker_platform: %s\n' "$docker_platform"
printf '  rest_api.publish_port: %s\n' "$publish_port"
printf '  tailscale.enabled: %s\n' "$tailscale_enabled"
printf '  output_path: %s\n' "$output_path"

if [ -f "$output_path" ]; then
    overwrite="$(prompt_yes_no "Output file already exists. Overwrite" "no")"
    if [ "$overwrite" != "yes" ]; then
        echo "No changes written."
        exit 0
    fi
fi

write_now="$(prompt_yes_no "Write DyeDNV file now" "yes")"
if [ "$write_now" != "yes" ]; then
    echo "No changes written."
    exit 0
fi

mkdir -p "$(dirname "$output_path")"

cat > "$output_path" <<JSON
{
  "schema_version": "dyednv.v1",
  "metadata": {
    "name": "$(json_escape "$name")",
    "environment": "$(json_escape "$environment")",
    "owner": "$(json_escape "$owner")",
    "created_at_utc": "$(json_escape "$created_at_utc")"
  },
  "teamserver": {
    "external_host": "$(json_escape "$external_host")",
    "profile_name": "$(json_escape "$profile_name")",
    "profile_intent": "$(json_escape "$profile_intent")"
  },
  "runtime": {
    "docker_platform": "$(json_escape "$docker_platform")",
    "mount_source": "$(json_escape "$mount_source")",
    "teamserver_host_override": "$(json_escape "$teamserver_host_override")"
  },
  "rest_api": {
    "rest_api_user": "$(json_escape "$rest_api_user")",
    "publish_bind": "$(json_escape "$publish_bind")",
    "publish_port": $publish_port,
    "service_bind_host": "$(json_escape "$service_bind_host")",
    "service_port": $service_port,
    "upstream_host": "$(json_escape "$upstream_host")",
    "upstream_port": $upstream_port,
    "healthcheck_url": "$(json_escape "$healthcheck_url")",
    "healthcheck_insecure": $healthcheck_insecure
  },
  "tailscale": {
    "enabled": $tailscale_enabled,
    "ts_userspace": $ts_userspace,
    "use_tailscale_ip": $use_tailscale_ip,
    "ts_extra_args": "$(json_escape "$ts_extra_args")"
  },
  "secret_refs": {
    "cobaltstrike_license_ref": "$(json_escape "$cobaltstrike_license_ref")",
    "teamserver_password_ref": "$(json_escape "$teamserver_password_ref")",
    "ts_authkey_ref": "$(json_escape "$ts_authkey_ref")",
    "ts_api_key_ref": "$(json_escape "$ts_api_key_ref")"
  }
}
JSON

echo
echo "Wrote DyeDNV file: $output_path"
echo "Next steps:"
echo "  1. Review: cat '$output_path'"
echo "  2. Resolve secret refs into your secure secret store workflow."
echo "  3. Apply resolved values to .env manually before running ./cobalt-docker.sh"
