# Roadmap: Cobalt-Docker

## Milestone History

- ✅ **v1.0 Runtime Hardening** — shipped 2026-02-25 ([roadmap archive](./milestones/v1.0-ROADMAP.md), [requirements archive](./milestones/v1.0-REQUIREMENTS.md))

## Active Milestone

### 🚧 v1.1 Branch Protection Governance

**Goal:** Define and operationalize branch protection and required-check governance for `master` and `release/**` with reproducible verification and exception handling.

**Scope:** Policy/governance only (runtime feature expansion deferred to v1.2).

## Phases

### Phase 5: Branch Protection Policy Contract
**Goal**: Establish exact governance policy contract for protected targets and required checks.
**Depends on**: v1.0 CI reliability workflow baseline
**Requirements**: GOV-01, GOV-02, GOV-03
**Success Criteria** (what must be TRUE):
  1. Protected branch targets are explicitly defined for `master` and `release/**`.
  2. Required checks are pinned exactly to the runtime reliability job names.
  3. PR review governance rules are explicit (approval threshold, stale review handling, conversation resolution).
**Plans**: 2/2 plans complete

Plans:
- [x] 05-01: Define policy baseline and branch/check matrix (completed 2026-02-25)
- [x] 05-02: Specify governance review and merge contract (completed 2026-02-25)

### Phase 6: Governance Verification & Exceptions
**Goal**: Ensure governance policy is auditable, reproducible, and resilient during emergency changes.
**Depends on**: Phase 5
**Requirements**: GOV-04, AUD-01, AUD-02
**Success Criteria** (what must be TRUE):
  1. Direct-push/force-push exception policy is least-privilege and explicit.
  2. Verification procedure can confirm settings through CLI/UI paths.
  3. Emergency exception workflow includes reconciliation ownership and closeout checks.
**Plans**: 2 plans

Plans:
- [ ] 06-01: Define governance verification procedure and audit commands
- [ ] 06-02: Define exception and recovery workflow with reconciliation checklist

## Progress

**Execution Order:**
Phases execute in numeric order: 5 -> 6

| Phase | Plans Complete | Status | Completed |
|-------|----------------|--------|-----------|
| 5. Branch Protection Policy Contract | 2/2 | Complete    | 2026-02-25 |
| 6. Governance Verification & Exceptions | 0/2 | Not started | - |
