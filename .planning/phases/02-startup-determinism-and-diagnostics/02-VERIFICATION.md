status: passed
score: 5/5

# Phase 2 Verification

## Goal
Ensure startup order, readiness checks, and failure handling are deterministic and operator-actionable.

## Requirement Checks
- CONF-03: passed
- STRT-01: passed
- STRT-02: passed
- STRT-03: passed
- STRT-04: passed

## Evidence
- `cobalt-docker.sh` now centralizes startup control validation with shared port/boolean helpers.
- Launcher preflight enforces strict boolean controls for `HEALTHCHECK_INSECURE`, `TS_USERSPACE`, and `USE_TAILSCALE_IP`.
- `docker-entrypoint.sh` startup sequence remains teamserver -> TLS readiness -> csrestapi -> HTTPS readiness, with bounded gate helpers.
- Entrypoint failure branches now emit phase-specific `STARTUP[...] ERROR:` diagnostics and exit non-zero.
- `README.md` and `AGENTS.md` now document startup marker contract and override-aware health verification commands.
- Shell syntax checks passed for both scripts and `./scripts/scan-secrets.sh /opt/Cobalt-Docker` returned no findings.

## Outcome
Phase 2 startup determinism and diagnostics requirements are satisfied with deterministic validation, sequencing, and operator triage behavior.
