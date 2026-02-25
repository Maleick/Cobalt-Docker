# Phase 5: Branch Protection Policy Contract - Research

**Researched:** 2026-02-25
**Domain:** GitHub branch governance policy contract for merge gate enforcement
**Confidence:** HIGH

## User Constraints

### Locked Decisions
- Plan directly for Phase 5 without discuss-phase pre-step (no `05-CONTEXT.md` in this pass).
- Keep phase scope limited to `GOV-01`, `GOV-02`, `GOV-03`.
- Use hybrid governance framing:
  - branch protection rules as baseline contract surface,
  - rulesets compatibility/migration notes included where relevant.
- Exclude v1.2 deferred scope:
  - CI depth expansion,
  - broader post-start operations documentation,
  - contributor evidence-flow improvements.

### Claude's Discretion
- Exact structure of policy matrix and acceptance checks.
- Exact split of implementation work between `05-01` and `05-02`.
- CLI/UI verification examples that support future execution in Phase 6 without expanding scope now.

### Deferred Ideas (Out of Phase Scope)
- `GOV-04`, `AUD-01`, `AUD-02` (Phase 6 scope).
- `REL-01`, `OPS-01`, `EVD-01` (v1.2 deferred requirements).

## Summary

Phase 5 should define a canonical policy contract for protected branches and merge gates, not implement broader operational governance flows. The primary output should be an explicit branch/check/review matrix that is stable, auditable, and directly mappable to repository settings. The contract must pin required checks exactly to existing workflow outputs:

- `runtime-reliability / syntax-checks`
- `runtime-reliability / shell-regression-suite`
- `runtime-reliability / secret-scan`

The recommended pattern is to treat branch protection as the baseline enforcement source for this milestone and include ruleset alignment notes so the contract remains migration-safe if rulesets become primary later.

## Current Baseline Findings

### Existing Inputs
- `ROADMAP.md` defines Phase 5 with 2 plans and requirements `GOV-01..03`.
- `REQUIREMENTS.md` maps `GOV-01..03` to Phase 5 and defers `GOV-04`/`AUD-*` to Phase 6.
- Existing runtime reliability workflow already publishes the three required checks.

### Gaps Phase 5 Must Close
- No phase-level policy matrix exists yet for branch targets and required checks.
- Review governance (approval threshold/stale review/conversation resolution) is not yet captured as executable planning tasks.
- No Phase 5 directory artifacts existed before this research pass.

## Recommended Patterns

### Pattern 1: Contract Matrix First
- Define explicit matrix by branch target (`master`, `release/**`) and governance dimensions:
  - required checks,
  - PR review settings,
  - stale review handling,
  - conversation resolution expectations.

### Pattern 2: Name-Pinned Required Checks
- Treat required check names as immutable contract values during v1.1.
- Any workflow job rename is a contract change that must be reflected in policy docs.

### Pattern 3: Hybrid Surface Notes
- Baseline: branch protection settings contract.
- Compatibility: include mapping notes for equivalent ruleset controls.
- Do not scope Phase 5 into full ruleset rollout execution.

### Pattern 4: Scope Guardrails by Requirement ID
- Every plan task should map to `GOV-01`, `GOV-02`, or `GOV-03`.
- Avoid including exception/recovery mechanics beyond dependency references to Phase 6.

## Risks and Mitigations

### Risk: Check Name Drift
- Mitigation: include explicit required-check list and verification command in plan tasks.

### Risk: Branch Pattern Ambiguity
- Mitigation: codify exact target patterns and expected coverage outcomes in policy matrix.

### Risk: Review Rule Underspecification
- Mitigation: require explicit approval count, stale review policy, and conversation resolution behavior in outputs.

### Risk: Phase Scope Bleed
- Mitigation: hard gate plan tasks to `GOV-01..03`; note Phase 6 items as dependencies only.

## Verification Strategy (for Planning Quality)

1. Requirement coverage check:
   - Ensure `05-01` + `05-02` frontmatter contains all `GOV-01..03`.
2. Plan structure check:
   - Run `gsd-tools verify plan-structure` on each plan file.
3. Scope check:
   - Confirm no plan tasks implement `GOV-04`/`AUD-*`.
4. Traceability check:
   - Ensure each task has actionable verify criteria tied to policy outputs.

## Sources

### Primary (HIGH confidence)
- `/opt/Cobalt-Docker/.planning/ROADMAP.md`
- `/opt/Cobalt-Docker/.planning/REQUIREMENTS.md`
- `/opt/Cobalt-Docker/.planning/STATE.md`
- `/opt/Cobalt-Docker/.planning/PROJECT.md`
- `/opt/Cobalt-Docker/.planning/research/SUMMARY.md`
- `/opt/Cobalt-Docker/.github/workflows/runtime-reliability-gates.yml`

### External reference docs (HIGH confidence)
- https://docs.github.com/articles/about-required-reviews-for-pull-requests
- https://docs.github.com/en/repositories/configuring-branches-and-merges-in-your-repository/managing-protected-branches/managing-a-branch-protection-rule
- https://docs.github.com/repositories/configuring-branches-and-merges-in-your-repository/managing-rulesets/about-rulesets

## Metadata
- Research mode: phase-specific
- Context source: roadmap + requirements + prior milestone research
- User decisions honored: yes
- Deferred ideas excluded: yes
