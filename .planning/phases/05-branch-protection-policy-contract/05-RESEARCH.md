# Phase 5: Branch Protection Policy Contract - Research

**Researched:** 2026-02-25
**Domain:** GitHub branch governance policy contract for merge gate enforcement
**Confidence:** HIGH

## User Constraints

### Locked Decisions (from 05-CONTEXT.md)
- Existing plans are draft-only and must be regenerated using context-aware defaults.
- Scope is limited to `GOV-01`, `GOV-02`, `GOV-03`.
- Governance surface is hybrid:
  - branch protection as baseline contract,
  - ruleset compatibility/migration notes only.
- Review governance defaults are fixed for this phase:
  - minimum approvals = 1,
  - stale approvals dismissed on new commits,
  - unresolved conversations block merge.
- Required checks are fixed to exact names:
  - `runtime-reliability / syntax-checks`
  - `runtime-reliability / shell-regression-suite`
  - `runtime-reliability / secret-scan`

### Claude's Discretion
- Policy document section ordering and matrix formatting.
- Wording detail that preserves the locked defaults.
- How to express compatibility notes without implying a ruleset rollout in Phase 5.

### Deferred Ideas (Out of Phase Scope)
- `GOV-04`, `AUD-01`, `AUD-02` (Phase 6).
- `REL-01`, `OPS-01`, `EVD-01` (v1.2 deferred).

## Summary

Phase 5 must produce an explicit policy contract for protected targets and required merge gates. It should not implement operational exception workflows, but it must define deterministic governance defaults that downstream execution can apply and verify. The strongest planning pattern is to center one canonical matrix that maps branch targets (`master`, `release/**`) to required checks and review settings.

The hybrid model should be represented as branch-protection-first with ruleset equivalence notes so the contract remains migration-safe. This prevents immediate scope expansion while still avoiding policy dead ends.

## Current Baseline Findings

### Existing Inputs
- `ROADMAP.md` defines Phase 5 goal and requirements (`GOV-01..03`).
- `REQUIREMENTS.md` maps `GOV-01..03` to Phase 5.
- `05-CONTEXT.md` now locks review defaults and scope boundaries.
- Existing runtime reliability workflow already emits the required checks.

### Gaps Phase 5 Must Close
- No canonical policy artifact yet defines branch target + check + review matrix.
- Existing plan drafts did not consume explicit context defaults.
- Phase output needs deterministic wording suitable for later verification and implementation.

## Recommended Patterns

### Pattern 1: Contract Matrix by Branch Target
- Rows: `master`, `release/**`.
- Columns: required checks, approval minimum, stale review handling, conversation resolution.
- Include explicit non-goals to prevent scope bleed.

### Pattern 2: Name-Pinned Check Contract
- Keep required checks as fixed string values.
- Treat check renames as contract changes that require policy update.

### Pattern 3: Locked Review Defaults
- Hard-code defaults in planning tasks:
  - 1 approval,
  - dismiss stale approvals,
  - unresolved conversations block merge.

### Pattern 4: Hybrid Compatibility Notes
- Baseline controls documented as branch protection.
- Separate section maps equivalent ruleset controls.
- No ruleset rollout tasking in Phase 5.

### Pattern 5: Strict Requirement Guardrail
- `05-01` should focus on `GOV-01` and `GOV-02`.
- `05-02` should focus on `GOV-03`.
- Any `GOV-04`/`AUD-*` mentions must remain dependency/deferred notes only.

## Risks and Mitigations

### Risk: Check name drift
- Mitigation: include exact required check strings in policy artifact and plan verification commands.

### Risk: Ambiguous review policy interpretation
- Mitigation: encode explicit numeric/boolean defaults in contract and plan tasks.

### Risk: Scope bleed into Phase 6
- Mitigation: include boundary section referencing `GOV-04`/`AUD-*` as out of phase.

### Risk: Branch target mismatch
- Mitigation: explicitly define protected patterns and expected governance coverage per target.

## Verification Strategy (for planning quality)

1. Coverage gate:
   - `05-01` + `05-02` frontmatter must include all `GOV-01..03`.
2. Context propagation gate:
   - plan context blocks must include `05-CONTEXT.md`.
3. Scope gate:
   - no Phase 5 tasks implement `GOV-04`/`AUD-*`.
4. Structure gate:
   - run `gsd-tools verify plan-structure` on both plans.

## Sources

### Primary (HIGH confidence)
- `/opt/Cobalt-Docker/.planning/phases/05-branch-protection-policy-contract/05-CONTEXT.md`
- `/opt/Cobalt-Docker/.planning/ROADMAP.md`
- `/opt/Cobalt-Docker/.planning/REQUIREMENTS.md`
- `/opt/Cobalt-Docker/.planning/STATE.md`
- `/opt/Cobalt-Docker/.planning/PROJECT.md`
- `/opt/Cobalt-Docker/.planning/research/SUMMARY.md`
- `/opt/Cobalt-Docker/.github/workflows/runtime-reliability-gates.yml`

### External references (HIGH confidence)
- https://docs.github.com/articles/about-required-reviews-for-pull-requests
- https://docs.github.com/en/repositories/configuring-branches-and-merges-in-your-repository/managing-protected-branches/managing-a-branch-protection-rule
- https://docs.github.com/repositories/configuring-branches-and-merges-in-your-repository/managing-rulesets/about-rulesets

## Metadata
- Research mode: phase-specific (refreshed)
- Context source: `05-CONTEXT.md` + roadmap/requirements + milestone research summary
- User decisions honored: yes
- Deferred ideas excluded: yes
