---
phase: 03-mount-platform-resilience-with-regression-tests
plan: 03
subsystem: testing
tags: [startup, readiness, entrypoint]
requires:
  - phase: 03-mount-platform-resilience-with-regression-tests
    provides: shell test harness and mount branch coverage
provides:
  - Startup sequencing/readiness regression tests for entrypoint
  - Entry-point testability hooks (binary path overrides and probe timeout control)
  - Documented one-command shell regression execution in README/AGENTS
affects: [phase-04-ci, operator-troubleshooting]
tech-stack:
  added: []
  patterns: [startup marker ordering assertions, timeout-controlled branch tests]
key-files:
  created: [tests/spec/docker-entrypoint.startup.sh]
  modified: [docker-entrypoint.sh, tests/run-shell-tests.sh, README.md, AGENTS.md]
key-decisions:
  - "Expose minimal entrypoint test hooks without changing production startup semantics"
  - "Verify startup ordering via stable STARTUP marker sequence checks"
patterns-established:
  - "Probe timeout is configurable for fast branch tests while default runtime behavior remains unchanged"
requirements-completed: [TEST-03]
duration: 26min
completed: 2026-02-25
---

# Phase 3 Plan 03 Summary

**Startup sequencing and readiness branches are now covered by deterministic shell regression tests keyed to `STARTUP[...]` marker order and failure paths.**

## Accomplishments
- Added `tests/spec/docker-entrypoint.startup.sh` with sequencing, timeout, and preflight validation cases.
- Added minimal entrypoint test hooks (`TEAMSERVER_BIN`, `REST_SERVER_DIR`, `REST_SERVER_BIN`, `STARTUP_PROBE_TIMEOUT_SECONDS`).
- Integrated startup specs into full suite execution and documented usage in README/AGENTS.

## Task Commits
- `a4cbfd0` — mount/platform hardening and shell regression suite

## Decisions Made
- Keep runtime defaults stable while exposing test-only controls via environment overrides.
- Use marker-order assertions to verify readiness ordering contract.

## Deviations from Plan
- None - plan executed within intended scope.

## Issues Encountered
- Test isolation required explicit `TS_AUTHKEY` neutralization to avoid host-env leakage into startup tests.

## Next Phase Readiness
- Phase 3 regression coverage is complete and ready to be enforced in CI (Phase 4 scope).

---
*Phase: 03-mount-platform-resilience-with-regression-tests*
*Completed: 2026-02-25*
