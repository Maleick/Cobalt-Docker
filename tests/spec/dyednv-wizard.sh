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

create_fixture() {
    local fixture
    fixture="$(mktemp -d)"

    mkdir -p "$fixture/scripts"
    cp "$ROOT_DIR/scripts/dyednv-wizard.sh" "$fixture/scripts/dyednv-wizard.sh"
    chmod +x "$fixture/scripts/dyednv-wizard.sh"

    cat > "$fixture/.env.example" <<'ENVEOF'
COBALTSTRIKE_LICENSE="replace-with-license-key"
TEAMSERVER_PASSWORD="replace-with-teamserver-password"
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

    printf '%s\n' "$fixture"
}

run_wizard() {
    local fixture="$1"
    local input_payload="$2"
    local output=""

    set +e
    output="$({
        printf '%s' "$input_payload" | (cd "$fixture" && ./scripts/dyednv-wizard.sh)
    } 2>&1)"
    rc=$?
    set -e

    printf '%s' "$output"
    return "$rc"
}

case_happy_path() {
    local name="happy path writes DyeDNV JSON"
    local fixture output rc file_path

    fixture="$(create_fixture)"

    output="$(run_wizard "$fixture" "acme-prod
prod
operator
10.42.99.10
ops.profile
baseline-profile
linux/amd64
$fixture

csrestapi
127.0.0.1
50443
0.0.0.0
50443
127.0.0.1
50050
https://127.0.0.1:50443/health
true
false
false
false

vault://cobaltstrike/license
vault://teamserver/password

yes
")"
    rc=$?

    file_path="$fixture/configs/dyednv/acme-prod.dyednv.json"

    if [ "$rc" -ne 0 ]; then
        record_fail "$name" "wizard exited non-zero"
        rm -rf "$fixture"
        return
    fi

    if [ ! -f "$file_path" ]; then
        record_fail "$name" "expected output file missing: $file_path"
        rm -rf "$fixture"
        return
    fi

    if ! assert_contains "$output" "Wrote DyeDNV file:"; then
        record_fail "$name" "missing success output"
        rm -rf "$fixture"
        return
    fi

    if ! rg -q '"schema_version": "dyednv.v1"' "$file_path"; then
        record_fail "$name" "schema_version missing"
        rm -rf "$fixture"
        return
    fi

    if ! rg -q '"name": "acme-prod"' "$file_path"; then
        record_fail "$name" "metadata.name missing"
        rm -rf "$fixture"
        return
    fi

    if ! rg -q '"cobaltstrike_license_ref": "vault://cobaltstrike/license"' "$file_path"; then
        record_fail "$name" "secret reference missing"
        rm -rf "$fixture"
        return
    fi

    record_pass "$name"
    rm -rf "$fixture"
}

case_port_validation_reprompt() {
    local name="invalid port re-prompts until valid"
    local fixture output rc file_path

    fixture="$(create_fixture)"

    output="$(run_wizard "$fixture" "acme-port
prod
operator
10.42.99.10

baseline
linux/amd64
$fixture

csrestapi
127.0.0.1
70000
50443
0.0.0.0
50443
127.0.0.1
50050
https://127.0.0.1:50443/health
true
false
false
false

vault://cobaltstrike/license
vault://teamserver/password

yes
")"
    rc=$?
    file_path="$fixture/configs/dyednv/acme-port.dyednv.json"

    if [ "$rc" -ne 0 ]; then
        record_fail "$name" "wizard exited non-zero"
        rm -rf "$fixture"
        return
    fi

    if ! assert_contains "$output" "Error: value must be an integer between 1 and 65535."; then
        record_fail "$name" "did not emit port validation error"
        rm -rf "$fixture"
        return
    fi

    if [ ! -f "$file_path" ]; then
        record_fail "$name" "expected output file missing"
        rm -rf "$fixture"
        return
    fi

    record_pass "$name"
    rm -rf "$fixture"
}

case_boolean_validation_reprompt() {
    local name="invalid boolean re-prompts until valid"
    local fixture output rc

    fixture="$(create_fixture)"

    output="$(run_wizard "$fixture" "acme-bool
prod
operator
10.42.99.10

baseline
linux/amd64
$fixture

csrestapi
127.0.0.1
50443
0.0.0.0
50443
127.0.0.1
50050
https://127.0.0.1:50443/health
maybe
true
false
false
false

vault://cobaltstrike/license
vault://teamserver/password

yes
")"
    rc=$?

    if [ "$rc" -ne 0 ]; then
        record_fail "$name" "wizard exited non-zero"
        rm -rf "$fixture"
        return
    fi

    if ! assert_contains "$output" "Error: value must be 'true' or 'false'."; then
        record_fail "$name" "did not emit boolean validation error"
        rm -rf "$fixture"
        return
    fi

    record_pass "$name"
    rm -rf "$fixture"
}

case_secret_hygiene_rejects_raw() {
    local name="raw secret-like input is rejected for secret refs"
    local fixture output rc file_path

    fixture="$(create_fixture)"

    output="$(run_wizard "$fixture" "acme-secret
prod
operator
10.42.99.10

baseline
linux/amd64
$fixture

csrestapi
127.0.0.1
50443
0.0.0.0
50443
127.0.0.1
50050
https://127.0.0.1:50443/health
true
false
false
false

tskey-auth-abc123
vault://cobaltstrike/license
vault://teamserver/password

yes
")"
    rc=$?
    file_path="$fixture/configs/dyednv/acme-secret.dyednv.json"

    if [ "$rc" -ne 0 ]; then
        record_fail "$name" "wizard exited non-zero"
        rm -rf "$fixture"
        return
    fi

    if ! assert_contains "$output" "Error: value looks like a raw secret. Store only secret references."; then
        record_fail "$name" "did not emit raw-secret rejection"
        rm -rf "$fixture"
        return
    fi

    if [ ! -f "$file_path" ]; then
        record_fail "$name" "expected output file missing"
        rm -rf "$fixture"
        return
    fi

    record_pass "$name"
    rm -rf "$fixture"
}

case_overwrite_decline_preserves_file() {
    local name="declining overwrite leaves existing file unchanged"
    local fixture output rc file_path before after

    fixture="$(create_fixture)"
    mkdir -p "$fixture/configs/dyednv"
    file_path="$fixture/configs/dyednv/acme-overwrite.dyednv.json"
    printf 'existing-content\n' > "$file_path"

    before="$(cat "$file_path")"

    output="$(run_wizard "$fixture" "acme-overwrite
prod
operator
10.42.99.10

baseline
linux/amd64
$fixture

csrestapi
127.0.0.1
50443
0.0.0.0
50443
127.0.0.1
50050
https://127.0.0.1:50443/health
true
false
false
false

vault://cobaltstrike/license
vault://teamserver/password

no
")"
    rc=$?

    after="$(cat "$file_path")"

    if [ "$rc" -ne 0 ]; then
        record_fail "$name" "wizard exited non-zero"
        rm -rf "$fixture"
        return
    fi

    if ! assert_contains "$output" "No changes written."; then
        record_fail "$name" "missing no-change message"
        rm -rf "$fixture"
        return
    fi

    if [ "$before" != "$after" ]; then
        record_fail "$name" "existing file changed despite overwrite decline"
        rm -rf "$fixture"
        return
    fi

    record_pass "$name"
    rm -rf "$fixture"
}

case_env_not_modified() {
    local name="wizard does not modify .env"
    local fixture output rc before after

    fixture="$(create_fixture)"
    cat > "$fixture/.env" <<'ENVEOF'
REST_API_USER="from-env"
REST_API_PUBLISH_PORT="50443"
HEALTHCHECK_INSECURE="true"
ENVEOF

    before="$(cksum "$fixture/.env")"

    output="$(run_wizard "$fixture" "acme-noenv
prod
operator
10.42.99.10

baseline
linux/amd64
$fixture

from-env
127.0.0.1
50443
0.0.0.0
50443
127.0.0.1
50050
https://127.0.0.1:50443/health
true
false
false
false

vault://cobaltstrike/license
vault://teamserver/password

yes
")"
    rc=$?

    after="$(cksum "$fixture/.env")"

    if [ "$rc" -ne 0 ]; then
        record_fail "$name" "wizard exited non-zero"
        rm -rf "$fixture"
        return
    fi

    if [ "$before" != "$after" ]; then
        record_fail "$name" ".env changed unexpectedly"
        rm -rf "$fixture"
        return
    fi

    if ! assert_contains "$output" "Wrote DyeDNV file:"; then
        record_fail "$name" "missing success output"
        rm -rf "$fixture"
        return
    fi

    record_pass "$name"
    rm -rf "$fixture"
}

case_happy_path
case_port_validation_reprompt
case_boolean_validation_reprompt
case_secret_hygiene_rejects_raw
case_overwrite_decline_preserves_file
case_env_not_modified

if [ "$fail_count" -ne 0 ]; then
    echo "dyednv wizard spec failed: $fail_count failing test(s), $pass_count passing"
    exit 1
fi

echo "dyednv wizard spec passed: $pass_count test(s)"
