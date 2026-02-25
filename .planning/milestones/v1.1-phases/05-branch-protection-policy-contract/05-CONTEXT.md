# Phase 5: Branch Protection Policy Contract - Context

**Gathered:** 2026-02-25
**Status:** Ready for planning

<domain>
## Phase Boundary

This phase defines the branch protection policy contract for `master` and `release/**` and pins required checks and review-governance behavior. It does not implement exception workflows or verification execution paths that belong to Phase 6.

</domain>

<decisions>
## Implementation Decisions

### Existing plans handling
- Existing Phase 5 plans are treated as drafts and must be regenerated after context capture.
- Replanning must consume this context directly.

### Branch target contract
- Protected targets are `master` and `release/**`.
- Policy text should be explicit about target scope and intended coverage outcomes.

### Required-check contract
- Required checks are pinned exactly to:
  - `runtime-reliability / syntax-checks`
  - `runtime-reliability / shell-regression-suite`
  - `runtime-reliability / secret-scan`
- Check-name changes are considered contract changes and require policy updates.

### Review governance defaults
- Minimum approval threshold: 1 approving review.
- Stale approvals are dismissed when new commits are pushed.
- Unresolved review conversations block merge until resolved.

### Governance surface framing
- Branch protection is the baseline contract surface.
- Ruleset compatibility/migration notes are included for future alignment.
- No ruleset-first rollout or migration execution in this phase.

### Scope guardrail
- In scope: `GOV-01`, `GOV-02`, `GOV-03`.
- Out of scope for this phase: `GOV-04`, `AUD-01`, `AUD-02`, and v1.2 deferred items.

### Claude's Discretion
- Exact section layout and wording inside policy artifact(s).
- How to organize compatibility notes for readability.
- Non-functional editorial structure that does not change locked policy defaults.

</decisions>

<specifics>
## Specific Ideas

- Use an explicit matrix format mapping branch target -> required checks -> review rules.
- Keep policy wording migration-safe by pairing branch-protection baseline with ruleset equivalence notes.
- Keep contract language deterministic enough for downstream verification and plan-checking.

</specifics>

<deferred>
## Deferred Ideas

- `GOV-04` (least-privilege direct-push/force-push exception policy) is Phase 6.
- `AUD-01` and `AUD-02` verification/exception reconciliation flows are Phase 6.
- v1.2 deferred: CI depth expansion, broader post-start ops docs, contributor evidence-flow improvements.

</deferred>

---
*Phase: 05-branch-protection-policy-contract*
*Context gathered: 2026-02-25*
