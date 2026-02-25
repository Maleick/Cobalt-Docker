# Phase 6: Governance Verification & Exceptions - Context

**Gathered:** 2026-02-25
**Status:** Ready for planning

<domain>
## Phase Boundary

This phase defines and documents exception governance, verification procedures, and reconciliation controls for branch protection policy enforcement. It operationalizes `GOV-04`, `AUD-01`, and `AUD-02` without reworking completed Phase 5 policy baseline decisions.

</domain>

<decisions>
## Implementation Decisions

### Discuss coverage mode
- Full Phase 6 sweep in one pass (exception policy + verification + reconciliation).

### Exception authority model (`GOV-04`)
- Exception approval requires two-person authorization:
  - one repo admin approver
  - one code owner approver
- Single-actor exception approval is not permitted by default.

### Exception expiration default
- Exception window default TTL is 4 hours.
- Extensions require re-approval under the same two-person authority model.

### Exception scope limit
- Exception scope is limited to one protected branch target per request.
- Exception scope is limited to one explicitly referenced change set.
- Cross-branch blanket exceptions are out of scope for default policy.

### Verification source of truth (`AUD-01`)
- CLI verification output is canonical when CLI and UI differ.
- UI state is corroborating evidence, not the final authority.

### Verification evidence minimum
- Each verification run must capture:
  - command output evidence
  - UI screenshot evidence
- Evidence must be attributable to the same protected target and verification window.

### Reconciliation ownership (`AUD-02`)
- Post-incident reconciliation requires joint sign-off by:
  - repo admin
  - code owner
- Both sign-offs are required for closure.

### Reconciliation SLA
- Reconciliation checklist completion SLA is 24 hours from exception use.
- Open reconciliations beyond SLA are treated as non-compliant and must be escalated.

### Scope guardrail
- In scope: `GOV-04`, `AUD-01`, `AUD-02`.
- Out of scope: CI depth expansion, broader ops handbook expansion, and v1.2 deferred evidence-flow improvements.
- Do not redefine completed Phase 5 contract content (`GOV-01`, `GOV-02`, `GOV-03`).

### Claude's Discretion
- Exact wording and section ordering for runbook/procedure artifacts.
- Command examples and evidence table formatting choices.
- Non-functional editorial structure that preserves locked policy defaults.

</decisions>

<specifics>
## Specific Ideas

- Use explicit procedure blocks for exception request -> approval -> execution -> reconciliation.
- Include a verification checklist that pairs each CLI command result with a corresponding UI screenshot reference.
- Include a reconciliation checklist with owner fields, timestamps, and sign-off capture points.
- Include an escalation note for SLA breaches to keep audit outcomes deterministic.

</specifics>

<deferred>
## Deferred Ideas

- v1.2 deferred items remain out of scope:
  - CI depth expansion
  - broader post-start operational documentation
  - contributor evidence-flow process expansion
- Any automation for direct branch-protection/ruleset mutation is deferred beyond this phase unless explicitly added by roadmap update.

</deferred>

---
*Phase: 06-governance-verification-exceptions*
*Context gathered: 2026-02-25*
