# Roadmap: Cobalt-Docker Runtime Hardening

## Overview

This roadmap hardens an existing deployment baseline in four phases: contract/security baseline, startup determinism, platform/test resilience, and CI+documentation lock-in. The sequence prioritizes operator safety and deterministic runtime behavior before broadening automation and maintainability guardrails.

## Phases

**Phase Numbering:**
- Integer phases (1, 2, 3): planned milestone work
- Decimal phases (2.1, 2.2): urgent insertions if needed

- [x] **Phase 1: Contract and Security Baseline** - Lock required contracts and secret-safe defaults (completed 2026-02-25)
- [x] **Phase 2: Startup Determinism and Diagnostics** - Make startup behavior consistently verifiable (completed 2026-02-25)
- [x] **Phase 3: Mount/Platform Resilience with Regression Tests** - Stabilize environment variance and test critical branches (completed 2026-02-25)
- [x] **Phase 4: CI Enforcement and Operator Runbook** - Enforce checks continuously and finalize troubleshooting guidance (completed 2026-02-25)

## Phase Details

### Phase 1: Contract and Security Baseline
**Goal**: Establish hard boundaries for required config, secret handling, and secure default exposure.
**Depends on**: Nothing (first phase)
**Requirements**: CONF-01, CONF-02, SEC-01, SEC-02, SEC-03, DOC-01
**Success Criteria** (what must be TRUE):
  1. Required `.env` contract is explicit, validated, and backed by a maintained template.
  2. Runtime and generated docs avoid secret value leakage and pass secret-pattern scans.
  3. REST API exposure defaults remain localhost-scoped unless explicitly overridden.
  4. README/AGENTS contract updates are tied to behavior changes.
**Plans**: 3/3 plans complete

Plans:
- [x] 01-01: Validate and normalize configuration/security contract boundaries
- [x] 01-02: Implement secret-safe output and scanning guardrails
- [x] 01-03: Align runtime defaults and contract documentation

### Phase 2: Startup Determinism and Diagnostics
**Goal**: Ensure startup order, readiness checks, and failure handling are deterministic and operator-actionable.
**Depends on**: Phase 1
**Requirements**: CONF-03, STRT-01, STRT-02, STRT-03, STRT-04
**Success Criteria** (what must be TRUE):
  1. Entrypoint always enforces teamserver readiness before REST API startup.
  2. Unexpected process exits during startup produce non-zero exit and clear cause.
  3. Health verification commands from docs reliably confirm healthy state.
  4. Startup logs include consistent phase markers for quick diagnosis.
**Plans**: 3/3 plans complete

Plans:
- [x] 02-01: Harden startup validation and failure semantics
- [x] 02-02: Strengthen readiness/liveness probes and branch behavior
- [x] 02-03: Improve startup diagnostic output and verification guidance

### Phase 3: Mount/Platform Resilience with Regression Tests
**Goal**: Make mount/platform behavior reliable and codify critical runtime branches in automated tests.
**Depends on**: Phase 2
**Requirements**: MNT-01, MNT-02, MNT-03, TEST-01, TEST-02, TEST-03
**Success Criteria** (what must be TRUE):
  1. Bind-vs-fallback mount behavior is deterministic and visible in operator logs.
  2. Platform-sensitive host/runtime path handling no longer fails silently.
  3. Automated shell tests cover preflight, mount mode, and startup sequencing branches.
  4. Test failures clearly identify the broken contract branch.
**Plans**: 3/3 plans complete

Plans:
- [x] 03-01: Harden mount and platform variance handling
- [x] 03-02: Add shell regression tests for preflight and mount branches
- [x] 03-03: Add startup sequencing/readiness regression tests

### Phase 4: CI Enforcement and Operator Runbook
**Goal**: Enforce reliability checks continuously and ship a clear troubleshooting runbook.
**Depends on**: Phase 3
**Requirements**: TEST-04, DOC-02
**Success Criteria** (what must be TRUE):
  1. Pull requests run syntax/static checks and shell regression tests in CI.
  2. Operator troubleshooting guidance covers startup, mount fallback, and health diagnostics end-to-end.
  3. Contributors can validate behavior quickly using documented commands.
**Plans**: 2/2 plans complete

Plans:
- [x] 04-01: Wire CI gates for shell/runtime contract checks
- [x] 04-02: Finalize operator troubleshooting and verification docs

## Progress

**Execution Order:**
Phases execute in numeric order: 1 -> 2 -> 3 -> 4

| Phase | Plans Complete | Status | Completed |
|-------|----------------|--------|-----------|
| 1. Contract and Security Baseline | 3/3 | Complete    | 2026-02-25 |
| 2. Startup Determinism and Diagnostics | 3/3 | Complete    | 2026-02-25 |
| 3. Mount/Platform Resilience with Regression Tests | 3/3 | Complete    | 2026-02-25 |
| 4. CI Enforcement and Operator Runbook | 2/2 | Complete    | 2026-02-25 |
