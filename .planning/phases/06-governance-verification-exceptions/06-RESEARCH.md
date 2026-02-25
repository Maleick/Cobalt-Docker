# Phase 6: Governance Verification & Exceptions - Research

**Researched:** 2026-02-25
**Domain:** Branch-protection governance verification, exception controls, and audit reconciliation
**Confidence:** HIGH

## User Constraints

### Locked Decisions (from 06-CONTEXT.md)
- Scope is limited to `GOV-04`, `AUD-01`, `AUD-02`.
- Exception approvals require two-person authorization:
  - one repo admin
  - one code owner
- Exception default TTL is 4 hours.
- Exception scope is single branch + single explicitly referenced change set.
- CLI verification output is canonical when CLI/UI differ.
- Verification evidence minimum is command output + UI screenshot.
- Reconciliation closure requires repo admin + code owner sign-off within 24 hours.

### Claude's Discretion
- Procedure document structure and section naming.
- Exact command examples for reproducible verification checks.
- Checklist formatting for reconciliation and escalation artifacts.

### Deferred Ideas (Out of Phase Scope)
- CI depth expansion.
- Broader operations handbook scope.
- v1.2 evidence-flow process expansion.

## Summary

Phase 6 should operationalize governance policy through deterministic procedures and exception controls, not redefine policy baseline. The strongest pattern is to split work into:

1. verification/audit procedure contract (`AUD-01`) tied to concrete evidence expectations,
2. emergency exception/reconciliation workflow (`GOV-04`, `AUD-02`) with strict authorization, TTL, and closeout controls.

The planning output should ensure that every exception can be traced from request to closure, with a fixed evidence bundle and explicit escalation when SLA is breached.

## Current Baseline Findings

### Existing Inputs
- `ROADMAP.md` defines Phase 6 goal and requirements (`GOV-04`, `AUD-01`, `AUD-02`).
- `REQUIREMENTS.md` maps those requirements to Phase 6.
- `06-CONTEXT.md` now locks exception/verification/reconciliation defaults.
- `.planning/milestones/v1.1-branch-protection-policy.md` already defines Phase 5 baseline and defers these operational controls to Phase 6.

### Gaps Phase 6 Must Close
- No operational exception workflow artifact currently exists.
- No auditable CLI/UI verification procedure currently exists.
- No reconciliation ownership + SLA enforcement checklist currently exists.

## Recommended Patterns

### Pattern 1: Deterministic Exception Ticket Model
- Capture: reason, branch target, change set reference, approvers, TTL start/end.
- Disallow unbounded or cross-branch default exceptions.

### Pattern 2: Canonical Verification Procedure
- CLI commands are authoritative result source.
- UI screenshots corroborate visual state and timestamp context.
- Require evidence pairing per protected target.

### Pattern 3: Structured Reconciliation Checklist
- Mandatory fields: incident ID, exception ID, approvers, closeout owner, closure timestamp.
- Joint sign-off by repo admin + code owner required for completion.
- Explicit escalation path when 24-hour SLA is exceeded.

### Pattern 4: Phase Boundary Enforcement
- Reference Phase 5 policy artifact as baseline input.
- Do not reopen branch scope/check-name/review-default decisions already completed in Phase 5.

## Risks and Mitigations

### Risk: Exception abuse through broad scope
- Mitigation: enforce single branch + single change set scope and 4-hour TTL.

### Risk: Evidence inconsistency across CLI/UI
- Mitigation: define CLI canonical precedence and require UI screenshot corroboration.

### Risk: Unclosed emergency exceptions
- Mitigation: 24-hour reconciliation SLA with named joint owners and escalation requirement.

### Risk: Phase scope bleed into broader operations
- Mitigation: keep outputs limited to governance verification and exception controls only.

## Verification Strategy (for planning quality)

1. Coverage gate:
   - `06-01` + `06-02` frontmatter must include all `GOV-04`, `AUD-01`, `AUD-02`.
2. Context propagation gate:
   - plan context blocks must include `06-CONTEXT.md`.
3. Scope gate:
   - no tasks redefine completed Phase 5 requirements (`GOV-01..03`).
4. Structure gate:
   - run `gsd-tools verify plan-structure` on both Phase 6 plans.

## Sources

### Primary (HIGH confidence)
- `/opt/Cobalt-Docker/.planning/phases/06-governance-verification-exceptions/06-CONTEXT.md`
- `/opt/Cobalt-Docker/.planning/ROADMAP.md`
- `/opt/Cobalt-Docker/.planning/REQUIREMENTS.md`
- `/opt/Cobalt-Docker/.planning/STATE.md`
- `/opt/Cobalt-Docker/.planning/milestones/v1.1-branch-protection-policy.md`
- `/opt/Cobalt-Docker/.planning/phases/05-branch-protection-policy-contract/05-VERIFICATION.md`

### External references (HIGH confidence)
- https://docs.github.com/en/repositories/configuring-branches-and-merges-in-your-repository/managing-protected-branches/managing-a-branch-protection-rule
- https://docs.github.com/articles/about-required-reviews-for-pull-requests
- https://docs.github.com/repositories/configuring-branches-and-merges-in-your-repository/managing-rulesets/about-rulesets

## Metadata
- Research mode: phase-specific
- Context source: `06-CONTEXT.md` + roadmap/requirements + Phase 5 policy baseline
- User decisions honored: yes
- Deferred ideas excluded: yes
