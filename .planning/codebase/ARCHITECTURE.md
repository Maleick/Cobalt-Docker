# Architecture

**Analysis Date:** 2026-02-25

## Pattern Overview

**Overall:** Host-driven Docker orchestration with in-container dual-process bootstrap.

**Key Characteristics:**
- Single canonical launcher (`cobalt-docker.sh`) controls build and runtime wiring.
- Entrypoint-level supervisor pattern in `docker-entrypoint.sh` starts teamserver then REST API with readiness gates.
- Fail-fast shell scripting style (`set -euo pipefail`) enforces strict preflight and startup checks.
- Optional network abstraction via Tailscale integration inside container runtime.

## Layers

**Operator/Launcher Layer:**
- Purpose: Validate config, select profile/mount strategy, build image, run container.
- Contains: `cobalt-docker.sh`
- Depends on: Docker CLI, host network/OS utilities.
- Used by: Human operator invoking `./cobalt-docker.sh`.

**Container Bootstrap Layer:**
- Purpose: Start and supervise required in-container processes with ordered readiness checks.
- Contains: `docker-entrypoint.sh`
- Depends on: `teamserver`, `csrestapi`, `openssl`, `curl`, optional `tailscale`.
- Used by: Docker container entrypoint from `Dockerfile`.

**Service Runtime Layer:**
- Purpose: Provide Cobalt Strike control plane and REST interface.
- Contains: `/opt/cobaltstrike/server/teamserver`, `/opt/cobaltstrike/server/rest-server/csrestapi` (inside image).
- Depends on: Java runtime and Cobalt Strike installation artifacts.
- Used by: Cobalt Strike clients and REST API consumers.

**Automation Layer:**
- Purpose: Repository-level GitHub automation for triage/review/invoke actions.
- Contains: `.github/workflows/*.yml`, `.github/commands/*.toml`
- Depends on: GitHub Actions, GitHub App auth, Gemini action.
- Used by: GitHub event triggers.

## Data Flow

**Standard Launch Flow:**
1. Operator runs `./cobalt-docker.sh [profile] [--lint]`.
2. Script reads `.env`, validates required keys, normalizes defaults.
3. Script builds image with license build arg and configures bind-mount/fallback profile mode.
4. Script runs container with port/env wiring and optional TUN device.
5. Container entrypoint starts `teamserver --experimental-db` and waits for TLS readiness.
6. Entrypoint launches `csrestapi` and waits for HTTPS health readiness.
7. Both processes are supervised; unexpected exit of either tears down container.

**State Management:**
- Configuration state is environment-variable driven (`.env` + runtime overrides).
- Runtime process state is PID-based inside `docker-entrypoint.sh` with trap-based cleanup.
- Persistent teamserver data/storage behavior is delegated to Cobalt Strike internals.

## Key Abstractions

**Mount Mode Selection:**
- Purpose: choose safe bind mount usage versus fallback in-image profiles.
- Examples: `docker_can_bind_mount_path`, `image_has_file`, `configure_mount_mode` in `cobalt-docker.sh`.
- Pattern: capability probe + guarded fallback.

**Readiness Probing:**
- Purpose: avoid starting dependent services before upstream is live.
- Examples: `tls_probe_endpoint`, `http_healthcheck` in `docker-entrypoint.sh`.
- Pattern: bounded polling loops with process-alive checks.

**Config Parsing Utility:**
- Purpose: robust `.env` parsing without sourcing arbitrary shell.
- Examples: `get_env_value`, `trim_whitespace`, `strip_wrapping_quotes`.
- Pattern: awk extraction + explicit value normalization.

## Entry Points

**Host Entry Point:**
- Location: `cobalt-docker.sh`
- Triggers: manual CLI invocation by operator
- Responsibilities: preflight, build, lint, and `docker run` orchestration

**Container Entry Point:**
- Location: `docker-entrypoint.sh` (configured in `Dockerfile`)
- Triggers: container startup
- Responsibilities: process startup ordering, readiness, cleanup, failure signaling

## Error Handling

**Strategy:** Fail fast with explicit error messages, non-zero exits, and cleanup traps.

**Patterns:**
- Input/config validation before side effects.
- Polling loops abort if required process exits early.
- `trap cleanup EXIT INT TERM` ensures subprocess termination.

## Cross-Cutting Concerns

**Logging:**
- Primarily plain stdout/stderr status lines from shell scripts.

**Validation:**
- Port and boolean validations in both launcher and entrypoint scripts.

**Security:**
- Secrets read from `.env` and passed via runtime env vars.
- REST API publish binding defaults to host localhost mapping.

---

*Architecture analysis: 2026-02-25*
*Update when major patterns change*
