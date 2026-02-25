# Project Research Summary

**Project:** Cobalt-Docker Runtime Hardening
**Domain:** Cobalt Strike Docker deployment hardening
**Researched:** 2026-02-25
**Confidence:** HIGH

## Executive Summary

This project is a runtime-hardening and execution-discipline effort, not a greenfield product build. The existing repository already provides a working deployment core (`cobalt-docker.sh` and `docker-entrypoint.sh`) with required preflight checks, ordered startup, and health probes. The highest-leverage path is to preserve that contract while improving safety, test coverage, and documentation reliability.

Research indicates the recommended approach is shell-first stabilization with explicit guardrails: add automated regression checks for critical shell branches, tighten security defaults and messaging, and continuously align docs with runtime behavior. The dominant risks are secret leakage, platform-specific assumptions, and drift between implementation and operator guidance.

## Key Findings

### Recommended Stack

The current Bash + Docker architecture is still the right execution model for this repository. Add supporting quality tools (`shellcheck`, `shfmt`, `bats-core`, optionally `hadolint`) rather than replacing orchestration wholesale.

**Core technologies:**
- Bash: runtime orchestration and contract enforcement
- Docker Engine/CLI: build and deployment runtime
- OpenSSL + curl: readiness probes and startup verification
- GitHub Actions: continuous contract validation

### Expected Features

**Must have (table stakes):**
- Required `.env` preflight and hard-fail behavior
- Ordered startup with explicit readiness gates
- Deterministic mount behavior with clear fallback semantics
- Secure default REST exposure and diagnostics operators can act on

**Should have (competitive):**
- Automated shell regression suite for critical branches
- Docs/runtime drift checks in CI

**Defer (v2+):**
- Multi-environment orchestration expansion
- Advanced observability integrations beyond current operational needs

### Architecture Approach

Maintain host launcher + in-container supervisor layering, then harden contracts through tests and clearer diagnostics. Keep startup semantics deterministic: validate config, probe capabilities, gate process startup, and fail with explicit causes.

**Major components:**
1. Host launcher (`cobalt-docker.sh`) — validation/build/run control plane
2. Container entrypoint (`docker-entrypoint.sh`) — startup sequencing and liveness management
3. Supporting docs/CI contracts — enforce behavior integrity over time

### Critical Pitfalls

1. **Secret leaks in logs/docs** — prevent with redaction and scanning gates
2. **Partial-health startups** — prevent with strict liveness-aware readiness checks
3. **Platform assumptions** — prevent with explicit portability checks and test coverage
4. **Docs/runtime drift** — prevent with phase-level contract updates and CI validation

## Implications for Roadmap

Based on research, suggested phase structure:

### Phase 1: Security and Contract Baseline
**Rationale:** Establish guardrails before making broader behavior changes.
**Delivers:** Secret-safe practices, clear contract boundaries, baseline validation policy.
**Addresses:** Must-have security and preflight expectations.
**Avoids:** Secret-leak and contract ambiguity pitfalls.

### Phase 2: Startup Determinism Hardening
**Rationale:** Startup sequencing is the critical runtime path.
**Delivers:** Explicit, testable startup and readiness semantics.
**Uses:** Existing probe and liveness patterns in current scripts.
**Implements:** Entrypoint/liveness contract hardening.

### Phase 3: Regression Test and Platform Resilience
**Rationale:** Reduce refactor risk and environment breakage.
**Delivers:** Automated shell regression checks and platform-oriented smoke coverage.
**Uses:** Supporting tooling (`bats-core`, `shellcheck`, CI workflows).

### Phase 4: Documentation and Maintainability Lock-in
**Rationale:** Keep operational guidance and implementation synchronized.
**Delivers:** Drift-resistant docs and contributor workflow conventions.

### Phase Ordering Rationale

- Security and contract clarity first, because every subsequent phase depends on trustworthy boundaries.
- Startup determinism second, because runtime ordering is highest-risk operational behavior.
- Automated tests third, because they codify known-good behavior for future changes.
- Documentation lock-in last, because it should capture finalized runtime/test contracts.

### Research Flags

Phases likely needing deeper research during planning:
- **Phase 3:** CI matrix strategy and deterministic shell test design details.

Phases with standard patterns (skip deep research-phase):
- **Phase 1, 2, 4:** established practices with strong repository-local context.

## Confidence Assessment

| Area | Confidence | Notes |
|------|------------|-------|
| Stack | HIGH | Directly matches current repository architecture |
| Features | HIGH | Derived from existing contract + concrete hardening goals |
| Architecture | HIGH | Current layering is explicit and already implemented |
| Pitfalls | HIGH | Confirmed by codebase concerns and common shell/runtime failure modes |

**Overall confidence:** HIGH

### Gaps to Address

- Exact CI matrix breadth for platform coverage should be right-sized to avoid noisy pipelines.
- Some source-of-truth drift (for example template/env artifacts) needs explicit phase treatment.

## Sources

### Primary (HIGH confidence)
- `.planning/codebase/*.md`
- `cobalt-docker.sh`, `docker-entrypoint.sh`, `Dockerfile`
- `README.md`, `AGENTS.md`

### Secondary (MEDIUM confidence)
- Docker and shell tooling official documentation for quality tooling choices

---
*Research completed: 2026-02-25*
*Ready for roadmap: yes*
