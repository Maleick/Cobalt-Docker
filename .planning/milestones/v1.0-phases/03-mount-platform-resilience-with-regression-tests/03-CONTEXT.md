# Phase 3: Mount/Platform Resilience with Regression Tests - Context

**Gathered:** 2026-02-25
**Status:** Ready for planning

<domain>
## Phase Boundary

This phase hardens mount/platform runtime behavior in the existing launcher and codifies branch behavior with automated shell regression tests. Scope is limited to deterministic mount/profile-source selection, resilient host/runtime host detection, and executable tests for preflight/mount/startup branches. It does not introduce new runtime services or CI policy changes beyond test artifacts.

</domain>

<decisions>
## Implementation Decisions

### Mount mode determinism
- Launcher must emit explicit mount mode selection in all branches (bind, fallback, or none/no-profile).
- Bind-vs-fallback decisions must remain probe-based and deterministic, with branch-specific cause messaging.
- Missing host mount path and daemon-visibility failures should be distinguishable in operator output.

### Profile source visibility
- When a profile is selected, output must clearly state whether profile source is bind-mounted host file or in-image fallback.
- Fallback profile path should be logged explicitly to aid diagnosis.
- Missing profile in fallback mode remains a hard failure with remediation guidance.

### Platform host/runtime resolution
- Host/runtime target resolution should handle Linux/macOS variance with multiple detection strategies before failing.
- Operator override for teamserver host/runtime target should be supported and explicit.
- Failures in host detection must include actionable guidance instead of generic silent/null behavior.

### Regression test shape and depth
- Add repository-local shell regression tests runnable with one command, no external test framework requirement.
- Test suite must cover:
  - preflight validation failures (TEST-01),
  - mount-mode branch behavior (TEST-02),
  - startup sequencing/readiness/failure branches (TEST-03).
- Failures should identify branch intent directly in test names/output.

### Claude's Discretion
- Exact helper/function names and internal shell organization.
- Exact test harness layout (single runner vs multiple spec scripts) as long as output is clear and deterministic.
- Documentation wording for test and mount diagnostics sections.

</decisions>

<specifics>
## Specific Ideas

- Keep `./cobalt-docker.sh` as the canonical operator entrypoint.
- Prefer explicit branch logging over implicit behavior for mount/source decisions.
- Keep tests self-contained via command stubs and temporary fixtures to avoid requiring Docker daemon execution in test mode.

</specifics>

<deferred>
## Deferred Ideas

- CI wiring for new shell tests is deferred to Phase 4 (`TEST-04`).
- Cross-host matrix execution beyond baseline Linux/macOS assumptions is deferred.
- Structured metrics/telemetry around mount branch frequency is deferred.

</deferred>

---
*Phase: 03-mount-platform-resilience-with-regression-tests*
*Context gathered: 2026-02-25*
