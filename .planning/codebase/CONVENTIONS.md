# Coding Conventions

**Analysis Date:** 2026-02-25

## Naming Patterns

**Files:**
- Runtime scripts use kebab-case: `cobalt-docker.sh`, `docker-entrypoint.sh`.
- Repository docs use uppercase file names for canonical references: `README.md`, `AGENTS.md`.
- CI automation files follow `gemini-<purpose>.yml` and `gemini-<purpose>.toml` patterns.

**Functions:**
- Shell helper functions use lower_snake_case: `get_env_value`, `configure_mount_mode`, `http_healthcheck`.
- Predicate functions are verb-oriented: `is_valid_port`, `docker_can_bind_mount_path`, `image_has_file`.

**Variables:**
- Configuration/constants use UPPER_SNAKE_CASE (`DOCKER_IMAGE_NAME`, `SERVICE_PORT`).
- Local temporaries inside functions use lower_snake_case (`raw_value`, `source_path`).
- Boolean flags use readable true/false strings (`DO_LINT`, `USE_BIND_MOUNT`, `HEALTHCHECK_INSECURE`).

## Code Style

**Formatting:**
- Shell scripts begin with strict mode: `set -euo pipefail`.
- Defensive quoting is used for expansions and command args (`"$VAR"`).
- Arrays are preferred for optional argument bundles (for example `DOCKER_MOUNT_ARGS`, `TUN_DEVICE_ARGS`).
- Scripts are heavily status-logged with `echo "==> ..."` markers for operator visibility.

**Linting/Validation:**
- Syntax validation is explicit via `bash -n /opt/Cobalt-Docker/cobalt-docker.sh` and `bash -n /opt/Cobalt-Docker/docker-entrypoint.sh`.
- No enforced formatter or shell linter config is currently committed.

## Import/Dependency Organization

**Order Pattern (shell level):**
1. Global constants and defaults.
2. Utility/helper functions.
3. Validation and configuration loaders.
4. Main execution flow at bottom.

**External Tool Usage:**
- Utilities are invoked directly (`docker`, `curl`, `openssl`, `awk`, `tailscale`).
- Commands favor explicit flags and guard checks before side effects.

## Error Handling

**Patterns:**
- Fail-fast validation with clear error text + `exit 1`.
- Preconditions are checked before long-running operations.
- Polling loops verify dependent process liveness before continuing.

**Error Types:**
- Missing/invalid config values fail immediately.
- Process startup failures fail the container run and trigger cleanup trap.
- Non-fatal conditions use `warn()` for degraded-mode communication.

## Logging

**Framework:**
- Plain shell stdout/stderr logs only.

**Patterns:**
- Startup phases are prefixed with `==>` for scan-friendly logs.
- Warnings are emitted through `warn()` to stderr.
- Diagnostic context is included in logs (selected profile, mount source, healthcheck URL).

## Comments

**When to Comment:**
- Comments focus on operational rationale and platform caveats.
- Inline comments explain non-obvious compatibility behavior (for example Docker Desktop mount visibility).

**TODO Tracking:**
- No formal TODO schema appears in scripts; open concerns are mostly handled through documentation updates.

## Function Design

**Size and Responsibility:**
- Helper functions encapsulate single responsibilities (parse env, probe mount, validate port).
- Main flow remains linear and grouped by numbered phases.

**Parameters/Returns:**
- Functions consume explicit positional parameters and return via stdout/exit status.
- Predicates return status codes for control flow in calling functions.

## Module Design

**Script Boundaries:**
- `cobalt-docker.sh`: host-orchestration concern.
- `docker-entrypoint.sh`: in-container orchestration concern.
- `Dockerfile`: build-time concern.

**Contract Enforcement:**
- `AGENTS.md` and `README.md` are treated as operational contract docs and should be updated with behavior changes.

---

*Convention analysis: 2026-02-25*
*Update when coding patterns change*
