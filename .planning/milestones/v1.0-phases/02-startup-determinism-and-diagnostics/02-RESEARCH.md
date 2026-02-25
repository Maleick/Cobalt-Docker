# Phase 2: Startup Determinism and Diagnostics - Research

**Researched:** 2026-02-25
**Domain:** Startup sequencing, runtime validation controls, and operator diagnostics
**Confidence:** HIGH

## User Constraints

### Locked Decisions (from CONTEXT.md)
- Launcher must fail fast on malformed startup controls before Docker build/run.
- Port controls must validate as integer range `1..65535`.
- Boolean controls must accept only `true`/`false` (case-insensitive input accepted, normalized before use).
- Entrypoint startup order is fixed: teamserver start -> teamserver TLS ready -> csrestapi start -> REST health ready.
- Startup failures must be non-zero and phase-specific with actionable cause.
- Logs should use consistent phase markers and include host/port probe context.
- README health verification commands must stay aligned to implemented behavior.

### Claude's Discretion
- Helper function names and marker text format.
- Small refactors that reduce duplicated readiness/error logic.
- Documentation phrasing details that preserve contract semantics.

### Deferred Ideas
- JSON/structured logging pipelines.
- Automatic restart policy/orchestration beyond current container lifecycle.
- Multi-environment startup profiles.

## Summary

Current scripts already implement the core startup contract, but determinism and diagnostics can be tightened in three places: (1) launcher-side control validation is incomplete for boolean runtime controls, (2) entrypoint logging is descriptive but not consistently phase-marked for fast grep/triage, and (3) documentation verification examples are default-only and should clearly map to configurable REST publish values. Phase 2 should standardize validation and phase markers without changing operator entrypoints or feature scope.

**Primary recommendation:** Keep runtime architecture unchanged and focus on deterministic guardrails: centralized validation helpers in launcher, phase-aware startup/failure logging in entrypoint, and docs that mirror verification behavior exactly.

## Existing Baseline Findings

### Launcher (`cobalt-docker.sh`)
- Strengths:
  - Required `.env` keys are enforced (`COBALTSTRIKE_LICENSE`, `TEAMSERVER_PASSWORD`).
  - Port validation already exists for `REST_API_PUBLISH_PORT`, `SERVICE_PORT`, `UPSTREAM_PORT`.
  - `HEALTHCHECK_INSECURE` is validated to `true|false`.
- Gaps against Phase 2 requirements:
  - `TS_USERSPACE` and `USE_TAILSCALE_IP` are not validated as booleans.
  - Validation logic is duplicated per setting instead of shared contract helpers.
  - Failure output for malformed controls can be made more uniform/actionable.

### Entrypoint (`docker-entrypoint.sh`)
- Strengths:
  - Enforces startup order with teamserver TLS readiness before REST startup.
  - Detects early process exits while waiting for readiness.
  - Exits non-zero on startup failure branches.
- Gaps against Phase 2 requirements:
  - Log messages are informative but not consistently phase-marked.
  - Failure lines can be standardized to include phase + cause + endpoint.
  - Readiness loops are split across repeated inline patterns.

### Documentation (`README.md`, `AGENTS.md`)
- Strengths:
  - Documents startup order and health checks.
  - Includes `curl` and `openssl` verification commands.
- Gaps against Phase 2 requirements:
  - Verification commands are anchored to default port examples; wording should make override-aware path explicit.
  - Startup marker contract is not documented as deterministic diagnostic output.

## Recommended Patterns

### Pattern 1: Unified runtime setting validators
Use reusable shell helpers for:
- `require_valid_port <key> <value>`
- `normalize_bool <key> <value> [default]`

Benefits: deterministic error text, less branch drift, easier maintenance.

### Pattern 2: Phase-marked startup logging
Use marker families such as:
- `STARTUP[preflight]`
- `STARTUP[teamserver-launch]`
- `STARTUP[teamserver-ready]`
- `STARTUP[rest-launch]`
- `STARTUP[rest-ready]`
- `STARTUP[monitor]`

Benefits: faster triage, reliable grep patterns, explicit phase transitions.

### Pattern 3: Probe wrappers with contextual failures
Wrap readiness loops in helper functions that:
- re-check process liveness each iteration,
- emit endpoint + timeout context on fail,
- return non-zero with deterministic branch message.

Benefits: clearer STRT-02 behavior and reduced logic duplication.

## Risks and Mitigations

### Risk: Over-validating optional settings can break existing lenient `.env` files
- Mitigation: permit empty values where defaults apply, validate only non-empty user-provided overrides.

### Risk: Marker verbosity can reduce readability
- Mitigation: keep markers short, single-line, and phase-specific; reserve details for failure branches.

### Risk: Docs drift from behavior after refactor
- Mitigation: include grep-able marker contract and run syntax/scan checks in plan verification.

## Verification Strategy

1. Syntax checks:
   - `bash -n /opt/Cobalt-Docker/cobalt-docker.sh`
   - `bash -n /opt/Cobalt-Docker/docker-entrypoint.sh`
2. Contract checks:
   - Confirm boolean validator coverage for `HEALTHCHECK_INSECURE`, `TS_USERSPACE`, `USE_TAILSCALE_IP`.
   - Confirm entrypoint startup markers exist for all major phases.
3. Docs parity:
   - Verify README health checks and startup behavior text align with updated script behavior.
4. Secret hygiene:
   - Run `./scripts/scan-secrets.sh`.

## Sources

### Primary (HIGH confidence)
- `/opt/Cobalt-Docker/cobalt-docker.sh`
- `/opt/Cobalt-Docker/docker-entrypoint.sh`
- `/opt/Cobalt-Docker/README.md`
- `/opt/Cobalt-Docker/AGENTS.md`
- `/opt/Cobalt-Docker/.planning/phases/02-startup-determinism-and-diagnostics/02-CONTEXT.md`

## Metadata
- Research mode: phase-specific
- User decisions honored: yes
- Deferred ideas excluded: yes
