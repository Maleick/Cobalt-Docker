# Phase 3: Mount/Platform Resilience with Regression Tests - Research

**Researched:** 2026-02-25
**Domain:** Launcher mount/platform branch hardening and shell regression coverage
**Confidence:** HIGH

## User Constraints

### Locked Decisions (from CONTEXT.md)
- Mount mode selection must be explicit and deterministic across bind/fallback/none branches.
- Selected profile source must be surfaced clearly for operators.
- Host/runtime target detection must handle Linux/macOS variance with actionable failure guidance.
- Tests must cover preflight validation, mount branches, and startup sequencing/readiness branches.
- Test output must identify failing branch intent directly.

### Claude's Discretion
- Internal helper organization for mount/platform detection.
- Test harness structure and naming conventions.
- Documentation phrasing for diagnostics and test execution.

### Deferred Ideas
- CI integration of the shell regression suite (Phase 4).
- Broad host matrix execution beyond local baseline assumptions.
- Telemetry/reporting features for startup/mount branch frequencies.

## Summary

The current runtime already implements core mount probing and fallback behavior, but branch visibility and platform host detection can still fail ambiguously under real operator conditions. The largest reliability gain is to make every mount and host-resolution branch explicit in logs and to enforce this behavior with automated shell tests that run entirely with stubs/fixtures. A lightweight native shell harness avoids external dependencies and provides deterministic branch-level assertions for preflight, mount selection, and startup sequencing.

**Primary recommendation:** introduce explicit mode/source diagnostics in `cobalt-docker.sh`, resilient host detection with override support, and a local shell test harness that simulates branch conditions via stubbed commands.

## Baseline Findings

### Launcher mount behavior (`cobalt-docker.sh`)
- Strengths:
  - Uses daemon-visibility probe for bind mount decisions.
  - Supports fallback to in-image profile when bind path is unavailable.
- Gaps:
  - No-profile branch can skip explicit mode/source diagnostics.
  - Missing host path vs daemon-invisible path is not consistently distinguished.
  - Profile source messaging can be clearer for triage and runbooks.

### Platform host resolution (`cobalt-docker.sh`)
- Strengths:
  - Basic Linux/macOS host detection exists.
- Gaps:
  - macOS assumes `en0` only.
  - Linux path depends on `hostname -I` only.
  - No explicit operator override path when auto-detection fails.

### Startup branch testability (`docker-entrypoint.sh`)
- Strengths:
  - Deterministic startup marker model exists from Phase 2.
  - Readiness and failure paths are centralized enough for branch testing.
- Gaps:
  - Hardcoded binary paths reduce test fixture flexibility.
  - Probe timeout is fixed at 60s, which is slow for regression tests.

## Recommended Patterns

### Pattern 1: Explicit mount mode + profile source contract
- Add stable output fields like `Mount mode:` and `Profile source:` for all run branches.
- Distinguish causes:
  - source missing,
  - source exists but daemon-invisible,
  - probe success.

### Pattern 2: Multi-strategy host detection with override
- Resolve host/runtime target in order:
  1. explicit override from config/env,
  2. primary OS strategy,
  3. fallback OS strategy,
  4. fail with remediation.

### Pattern 3: Stub-driven shell regression tests
- Use temporary fixtures and `PATH` command stubs to simulate:
  - Docker probe success/failure,
  - startup probe sequencing (openssl/curl),
  - process exits.
- Keep test runner one-command and branch-labeled.

## Risks and Mitigations

### Risk: Overly strict output matching in tests causes brittleness
- Mitigation: assert stable marker substrings, not full-line exact text.

### Risk: New host override could mask detection bugs if overused
- Mitigation: keep auto-detection as default; log when override is active.

### Risk: Test harness drift from runtime behavior
- Mitigation: test scripts call real launcher/entrypoint files with only external commands stubbed.

## Verification Strategy

1. Syntax checks:
   - `bash -n /opt/Cobalt-Docker/cobalt-docker.sh`
   - `bash -n /opt/Cobalt-Docker/docker-entrypoint.sh`
2. Regression suite:
   - `./tests/run-shell-tests.sh`
3. Secret hygiene:
   - `./scripts/scan-secrets.sh /opt/Cobalt-Docker`

## Sources

### Primary (HIGH confidence)
- `/opt/Cobalt-Docker/cobalt-docker.sh`
- `/opt/Cobalt-Docker/docker-entrypoint.sh`
- `/opt/Cobalt-Docker/README.md`
- `/opt/Cobalt-Docker/AGENTS.md`
- `/opt/Cobalt-Docker/.planning/phases/03-mount-platform-resilience-with-regression-tests/03-CONTEXT.md`

## Metadata
- Research mode: phase-specific
- User decisions honored: yes
- Deferred ideas excluded: yes
