#!/usr/bin/env bash

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"

pass_count=0
fail_count=0

record_pass() {
    local name="$1"
    echo "  [PASS] $name"
    pass_count=$((pass_count + 1))
}

record_fail() {
    local name="$1"
    local reason="$2"
    echo "  [FAIL] $name: $reason"
    fail_count=$((fail_count + 1))
}

assert_contains() {
    local haystack="$1"
    local needle="$2"
    if [[ "$haystack" != *"$needle"* ]]; then
        return 1
    fi
    return 0
}

replace_env_value() {
    local file_path="$1"
    local key="$2"
    local new_value="$3"
    local tmp_file
    tmp_file="$(mktemp)"

    awk -v key="$key" -v new_value="$new_value" '
        index($0, key "=") == 1 {
            print key "=\"" new_value "\""
            next
        }
        { print }
    ' "$file_path" > "$tmp_file"

    mv "$tmp_file" "$file_path"
}

create_fixture() {
    local fixture
    fixture="$(mktemp -d)"

    cp "$ROOT_DIR/cobalt-docker.sh" "$fixture/cobalt-docker.sh"
    chmod +x "$fixture/cobalt-docker.sh"

    cat >"$fixture/.env" <<'ENVEOF'
COBALTSTRIKE_LICENSE="test-license"
TEAMSERVER_PASSWORD="test-password"
REST_API_USER="csrestapi"
REST_API_PUBLISH_PORT="50443"
REST_API_PUBLISH_BIND="127.0.0.1"
SERVICE_BIND_HOST="0.0.0.0"
SERVICE_PORT="50443"
UPSTREAM_HOST="127.0.0.1"
UPSTREAM_PORT="50050"
HEALTHCHECK_URL="https://127.0.0.1:50443/health"
HEALTHCHECK_INSECURE="true"
TS_AUTHKEY=""
TS_API_KEY=""
TS_EXTRA_ARGS=""
TS_USERSPACE="false"
USE_TAILSCALE_IP="false"
TEAMSERVER_HOST_OVERRIDE=""
ENVEOF

    mkdir -p "$fixture/stubs"

    cat >"$fixture/stubs/docker" <<'STUBEOF'
#!/usr/bin/env bash
set -euo pipefail

if [ -n "${DOCKER_STUB_LOG:-}" ]; then
    printf '%s\n' "$*" >> "$DOCKER_STUB_LOG"
fi

subcommand="${1:-}"
case "$subcommand" in
    build|rm)
        exit 0
        ;;
    run)
        args="$*"
        if [[ "$args" == *"type=bind"* && "$args" == *"target=/mnt"* ]]; then
            if [ "${DOCKER_STUB_PROBE_RESULT:-success}" = "fail" ]; then
                exit 1
            fi
            exit 0
        fi

        if [[ "$args" == *"test -f"* ]]; then
            if [ "${DOCKER_STUB_IMAGE_HAS_FILE:-yes}" = "yes" ]; then
                exit 0
            fi
            exit 1
        fi

        exit 0
        ;;
    *)
        exit 0
        ;;
esac
STUBEOF

    cat >"$fixture/stubs/uname" <<'STUBEOF'
#!/usr/bin/env bash
printf '%s\n' "${UNAME_STUB:-Linux}"
STUBEOF

    cat >"$fixture/stubs/hostname" <<'STUBEOF'
#!/usr/bin/env bash
if [ "${1:-}" = "-I" ]; then
    printf '%s\n' "${HOSTNAME_I_STUB:-192.0.2.10}"
    exit 0
fi
printf 'fixture-host\n'
STUBEOF

    cat >"$fixture/stubs/ip" <<'STUBEOF'
#!/usr/bin/env bash
if [ "${1:-}" = "route" ] && [ "${2:-}" = "get" ]; then
    printf '1.1.1.1 via 192.0.2.1 dev eth0 src 192.0.2.20 \n'
    exit 0
fi
exit 0
STUBEOF

    cat >"$fixture/stubs/route" <<'STUBEOF'
#!/usr/bin/env bash
printf '   interface: en0\n'
STUBEOF

    cat >"$fixture/stubs/ipconfig" <<'STUBEOF'
#!/usr/bin/env bash
if [ "${1:-}" = "getifaddr" ]; then
    printf '192.0.2.30\n'
    exit 0
fi
exit 1
STUBEOF

    cat >"$fixture/stubs/ifconfig" <<'STUBEOF'
#!/usr/bin/env bash
printf 'en0: flags=8863<UP,BROADCAST,RUNNING> mtu 1500\n'
printf '    inet 192.0.2.31 netmask 0xffffff00 broadcast 192.0.2.255\n'
STUBEOF

    chmod +x "$fixture/stubs"/*
    printf '%s\n' "$fixture"
}

run_script() {
    local fixture="$1"
    local profile_arg="${2:-}"
    local output=""

    set +e
    if [ -n "$profile_arg" ]; then
        output="$({
            PATH="$fixture/stubs:$PATH" \
            DOCKER_STUB_LOG="${DOCKER_STUB_LOG:-}" \
            DOCKER_STUB_PROBE_RESULT="${DOCKER_STUB_PROBE_RESULT:-}" \
            DOCKER_STUB_IMAGE_HAS_FILE="${DOCKER_STUB_IMAGE_HAS_FILE:-}" \
            REST_API_PUBLISH_BIND="" \
            TEAMSERVER_HOST_OVERRIDE="${TEAMSERVER_HOST_OVERRIDE:-}" \
            UNAME_STUB="${UNAME_STUB:-}" \
            HOSTNAME_I_STUB="${HOSTNAME_I_STUB:-}" \
            "$fixture/cobalt-docker.sh" "$profile_arg"
        } 2>&1)"
    else
        output="$({
            PATH="$fixture/stubs:$PATH" \
            DOCKER_STUB_LOG="${DOCKER_STUB_LOG:-}" \
            DOCKER_STUB_PROBE_RESULT="${DOCKER_STUB_PROBE_RESULT:-}" \
            DOCKER_STUB_IMAGE_HAS_FILE="${DOCKER_STUB_IMAGE_HAS_FILE:-}" \
            REST_API_PUBLISH_BIND="" \
            TEAMSERVER_HOST_OVERRIDE="${TEAMSERVER_HOST_OVERRIDE:-}" \
            UNAME_STUB="${UNAME_STUB:-}" \
            HOSTNAME_I_STUB="${HOSTNAME_I_STUB:-}" \
            "$fixture/cobalt-docker.sh"
        } 2>&1)"
    fi
    rc=$?
    set -e

    printf '%s' "$output"
    return "$rc"
}

case_invalid_boolean_fails_preflight() {
    local name="preflight rejects invalid HEALTHCHECK_INSECURE"
    local fixture
    fixture="$(create_fixture)"

    replace_env_value "$fixture/.env" "HEALTHCHECK_INSECURE" "maybe"

    set +e
    output="$(run_script "$fixture")"
    rc=$?
    set -e

    rm -rf "$fixture"

    if [ "$rc" -eq 0 ]; then
        record_fail "$name" "expected non-zero exit"
        return
    fi

    if ! assert_contains "$output" "HEALTHCHECK_INSECURE must be 'true' or 'false'"; then
        record_fail "$name" "missing branch-specific validation error"
        return
    fi

    record_pass "$name"
}

case_invalid_port_fails_preflight() {
    local name="preflight rejects invalid SERVICE_PORT"
    local fixture
    fixture="$(create_fixture)"

    replace_env_value "$fixture/.env" "SERVICE_PORT" "70000"

    set +e
    output="$(run_script "$fixture")"
    rc=$?
    set -e

    rm -rf "$fixture"

    if [ "$rc" -eq 0 ]; then
        record_fail "$name" "expected non-zero exit"
        return
    fi

    if ! assert_contains "$output" "SERVICE_PORT must be an integer between 1 and 65535"; then
        record_fail "$name" "missing invalid-port validation output"
        return
    fi

    record_pass "$name"
}

case_profile_fallback_mode_visible() {
    local name="profile fallback branch logs mount mode and profile source"
    local fixture
    fixture="$(create_fixture)"

    set +e
    output="$({
        DOCKER_STUB_PROBE_RESULT=fail \
        DOCKER_STUB_IMAGE_HAS_FILE=yes \
        run_script "$fixture" "ops.profile"
    } 2>&1)"
    rc=$?
    set -e

    rm -rf "$fixture"

    if [ "$rc" -ne 0 ]; then
        record_fail "$name" "expected success through fallback path"
        return
    fi

    if ! assert_contains "$output" "Mount mode: fallback"; then
        record_fail "$name" "missing fallback mount-mode marker"
        return
    fi

    if ! assert_contains "$output" "Profile source: in-image profile: /opt/cobaltstrike/mount/ops.profile"; then
        record_fail "$name" "missing in-image profile source marker"
        return
    fi

    record_pass "$name"
}

case_no_profile_mode_visible_when_probe_fails() {
    local name="no-profile branch logs explicit none mount mode"
    local fixture
    fixture="$(create_fixture)"

    set +e
    output="$({
        DOCKER_STUB_PROBE_RESULT=fail \
        run_script "$fixture"
    } 2>&1)"
    rc=$?
    set -e

    rm -rf "$fixture"

    if [ "$rc" -ne 0 ]; then
        record_fail "$name" "expected success with no-profile mode"
        return
    fi

    if ! assert_contains "$output" "Mount mode: none"; then
        record_fail "$name" "missing none mount-mode marker"
        return
    fi

    if ! assert_contains "$output" "Profile source: none (no profile selected)"; then
        record_fail "$name" "missing no-profile source marker"
        return
    fi

    record_pass "$name"
}

case_host_override_handles_platform_variance() {
    local name="TEAMSERVER_HOST_OVERRIDE bypasses unsupported OS host detection"
    local fixture
    fixture="$(create_fixture)"

    set +e
    output="$({
        UNAME_STUB=UnknownOS \
        TEAMSERVER_HOST_OVERRIDE=203.0.113.77 \
        run_script "$fixture"
    } 2>&1)"
    rc=$?
    set -e

    rm -rf "$fixture"

    if [ "$rc" -ne 0 ]; then
        record_fail "$name" "expected success with explicit host override"
        return
    fi

    if ! assert_contains "$output" "Using TEAMSERVER_HOST_OVERRIDE: 203.0.113.77"; then
        record_fail "$name" "missing host-override confirmation output"
        return
    fi

    record_pass "$name"
}

case_invalid_boolean_fails_preflight
case_invalid_port_fails_preflight
case_profile_fallback_mode_visible
case_no_profile_mode_visible_when_probe_fails
case_host_override_handles_platform_variance

if [ "$fail_count" -ne 0 ]; then
    echo "cobalt-docker preflight/mount spec failed: $fail_count failure(s), $pass_count pass(es)"
    exit 1
fi

echo "cobalt-docker preflight/mount spec passed: $pass_count test(s)"
