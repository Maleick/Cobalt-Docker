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
    [[ "$haystack" == *"$needle"* ]]
}

make_fixture() {
    local fixture
    fixture="$(mktemp -d)"

    cp "$ROOT_DIR/docker-entrypoint.sh" "$fixture/docker-entrypoint.sh"
    chmod +x "$fixture/docker-entrypoint.sh"

    mkdir -p "$fixture/bin" "$fixture/rest" "$fixture/stubs"

    cat >"$fixture/bin/teamserver" <<'STUBEOF'
#!/usr/bin/env bash
set -euo pipefail
sleep "${TEAMSERVER_STUB_SLEEP:-0}"
exit "${TEAMSERVER_STUB_EXIT_CODE:-0}"
STUBEOF

    cat >"$fixture/rest/csrestapi" <<'STUBEOF'
#!/usr/bin/env bash
set -euo pipefail
sleep "${CSRESTAPI_STUB_SLEEP:-0}"
exit "${CSRESTAPI_STUB_EXIT_CODE:-0}"
STUBEOF

    cat >"$fixture/stubs/openssl" <<'STUBEOF'
#!/usr/bin/env bash
set -euo pipefail

counter_file="${OPENSSL_COUNTER_FILE:-}"
if [ -n "$counter_file" ]; then
    count=0
    if [ -f "$counter_file" ]; then
        count="$(cat "$counter_file")"
    fi
    count=$((count + 1))
    printf '%s\n' "$count" > "$counter_file"

    if [ "$count" -le "${OPENSSL_FAIL_COUNT:-0}" ]; then
        exit 1
    fi
fi

if [ "${OPENSSL_FORCE_FAIL:-0}" = "1" ]; then
    exit 1
fi

exit 0
STUBEOF

    cat >"$fixture/stubs/curl" <<'STUBEOF'
#!/usr/bin/env bash
set -euo pipefail

mode="${CURL_MODE:-success}"
case "$mode" in
    success)
        printf '%s' "${CURL_SUCCESS_CODE:-200}"
        ;;
    fail500)
        printf '500'
        ;;
    fail503)
        printf '503'
        ;;
    *)
        printf '500'
        ;;
esac

exit 0
STUBEOF

    cat >"$fixture/stubs/tailscaled" <<'STUBEOF'
#!/usr/bin/env bash
exit 0
STUBEOF

    cat >"$fixture/stubs/tailscale" <<'STUBEOF'
#!/usr/bin/env bash
set -euo pipefail

case "${1:-}" in
    status)
        exit 0
        ;;
    up)
        exit 0
        ;;
    ip)
        printf '%s\n' "${TAILSCALE_IP_STUB:-100.64.0.1}"
        exit 0
        ;;
    *)
        exit 0
        ;;
esac
STUBEOF

    chmod +x \
        "$fixture/bin/teamserver" \
        "$fixture/rest/csrestapi" \
        "$fixture/stubs/openssl" \
        "$fixture/stubs/curl" \
        "$fixture/stubs/tailscaled" \
        "$fixture/stubs/tailscale"
    printf '%s\n' "$fixture"
}

run_entrypoint() {
    local fixture="$1"
    shift

    local output=""

    set +e
    output="$({
        PATH="$fixture/stubs:$PATH" \
        TEAMSERVER_BIN="$fixture/bin/teamserver" \
        REST_SERVER_DIR="$fixture/rest" \
        REST_SERVER_BIN="$fixture/rest/csrestapi" \
        TEAMSERVER_STUB_SLEEP="${TEAMSERVER_STUB_SLEEP:-0}" \
        TEAMSERVER_STUB_EXIT_CODE="${TEAMSERVER_STUB_EXIT_CODE:-0}" \
        CSRESTAPI_STUB_SLEEP="${CSRESTAPI_STUB_SLEEP:-0}" \
        CSRESTAPI_STUB_EXIT_CODE="${CSRESTAPI_STUB_EXIT_CODE:-0}" \
        OPENSSL_COUNTER_FILE="${OPENSSL_COUNTER_FILE:-}" \
        OPENSSL_FAIL_COUNT="${OPENSSL_FAIL_COUNT:-0}" \
        OPENSSL_FORCE_FAIL="${OPENSSL_FORCE_FAIL:-0}" \
        CURL_MODE="${CURL_MODE:-success}" \
        CURL_SUCCESS_CODE="${CURL_SUCCESS_CODE:-200}" \
        TS_AUTHKEY="" \
        TS_EXTRA_ARGS="" \
        TS_USERSPACE="false" \
        USE_TAILSCALE_IP="false" \
        STARTUP_PROBE_TIMEOUT_SECONDS="${STARTUP_PROBE_TIMEOUT_SECONDS:-2}" \
        "$fixture/docker-entrypoint.sh" "$@"
    } 2>&1)"
    rc=$?
    set -e

    printf '%s' "$output"
    return "$rc"
}

case_teamserver_exits_before_readiness() {
    local name="startup fails when teamserver exits before readiness"
    local fixture
    fixture="$(make_fixture)"

    set +e
    output="$({
        TEAMSERVER_STUB_SLEEP=0 \
        TEAMSERVER_STUB_EXIT_CODE=1 \
        OPENSSL_FORCE_FAIL=1 \
        STARTUP_PROBE_TIMEOUT_SECONDS=2 \
        run_entrypoint "$fixture" "198.51.100.10" "secret"
    } 2>&1)"
    rc=$?
    set -e

    rm -rf "$fixture"

    if [ "$rc" -eq 0 ]; then
        record_fail "$name" "expected non-zero exit"
        return
    fi

    if ! assert_contains "$output" "STARTUP[teamserver-ready] ERROR: teamserver exited before becoming TLS-ready"; then
        record_fail "$name" "missing teamserver-ready failure marker"
        return
    fi

    record_pass "$name"
}

case_rest_starts_after_teamserver_ready() {
    local name="rest launch happens after teamserver readiness marker"
    local fixture
    local openssl_counter
    fixture="$(make_fixture)"
    openssl_counter="$fixture/openssl.count"

    set +e
    output="$({
        TEAMSERVER_STUB_SLEEP=4 \
        TEAMSERVER_STUB_EXIT_CODE=0 \
        CSRESTAPI_STUB_SLEEP=1 \
        CSRESTAPI_STUB_EXIT_CODE=0 \
        OPENSSL_COUNTER_FILE="$openssl_counter" \
        OPENSSL_FAIL_COUNT=1 \
        CURL_MODE=success \
        STARTUP_PROBE_TIMEOUT_SECONDS=4 \
        run_entrypoint "$fixture" "198.51.100.20" "secret"
    } 2>&1)"
    rc=$?
    set -e

    rm -rf "$fixture"

    if [ "$rc" -eq 0 ]; then
        record_fail "$name" "expected monitor failure after startup"
        return
    fi

    line_ready="$(printf '%s\n' "$output" | awk '/STARTUP\[teamserver-ready\] TLS readiness confirmed/ { print NR; exit }')"
    line_rest_launch="$(printf '%s\n' "$output" | awk '/STARTUP\[rest-launch\]/ { print NR; exit }')"

    if [ -z "$line_ready" ] || [ -z "$line_rest_launch" ]; then
        record_fail "$name" "missing startup markers for readiness/launch"
        return
    fi

    if [ "$line_rest_launch" -le "$line_ready" ]; then
        record_fail "$name" "rest-launch marker appeared before teamserver readiness confirmation"
        return
    fi

    if ! assert_contains "$output" "STARTUP[rest-ready] REST API healthcheck reachable"; then
        record_fail "$name" "missing rest-ready success marker"
        return
    fi

    record_pass "$name"
}

case_rest_health_timeout_reports_branch() {
    local name="rest health timeout branch is explicit"
    local fixture
    fixture="$(make_fixture)"

    set +e
    output="$({
        TEAMSERVER_STUB_SLEEP=5 \
        TEAMSERVER_STUB_EXIT_CODE=0 \
        CSRESTAPI_STUB_SLEEP=5 \
        CSRESTAPI_STUB_EXIT_CODE=0 \
        OPENSSL_FAIL_COUNT=0 \
        CURL_MODE=fail500 \
        STARTUP_PROBE_TIMEOUT_SECONDS=2 \
        run_entrypoint "$fixture" "198.51.100.30" "secret"
    } 2>&1)"
    rc=$?
    set -e

    rm -rf "$fixture"

    if [ "$rc" -eq 0 ]; then
        record_fail "$name" "expected non-zero timeout exit"
        return
    fi

    if ! assert_contains "$output" "STARTUP[rest-ready] ERROR: REST API healthcheck failed"; then
        record_fail "$name" "missing rest-ready timeout marker"
        return
    fi

    record_pass "$name"
}

case_invalid_probe_timeout_fails_preflight() {
    local name="invalid startup probe timeout fails preflight"
    local fixture
    fixture="$(make_fixture)"

    set +e
    output="$({
        STARTUP_PROBE_TIMEOUT_SECONDS=0 \
        run_entrypoint "$fixture" "198.51.100.40" "secret"
    } 2>&1)"
    rc=$?
    set -e

    rm -rf "$fixture"

    if [ "$rc" -eq 0 ]; then
        record_fail "$name" "expected non-zero preflight exit"
        return
    fi

    if ! assert_contains "$output" "STARTUP[preflight] ERROR: STARTUP_PROBE_TIMEOUT_SECONDS must be a positive integer"; then
        record_fail "$name" "missing probe-timeout validation marker"
        return
    fi

    record_pass "$name"
}

case_teamserver_exits_before_readiness
case_rest_starts_after_teamserver_ready
case_rest_health_timeout_reports_branch
case_invalid_probe_timeout_fails_preflight

if [ "$fail_count" -ne 0 ]; then
    echo "docker-entrypoint startup spec failed: $fail_count failure(s), $pass_count pass(es)"
    exit 1
fi

echo "docker-entrypoint startup spec passed: $pass_count test(s)"
