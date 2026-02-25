# Project Research Summary

**Project:** Cobalt-Docker Runtime Hardening
**Domain:** GitHub branch protection governance for CI policy enforcement
**Researched:** 2026-02-25
**Confidence:** HIGH

## Executive Summary

This milestone should treat branch governance as a policy contract layered on top of the runtime reliability checks already implemented in-repo. The most reliable path is to define explicit protected branch targets (`master`, `release/**`), pin exact required checks, and document review/exception rules so enforcement behavior is predictable.

Research indicates that required-check reliability depends on stable and unique job names, and that governance quality improves when bypass permissions are constrained and auditable. A read-after-write verification loop via `gh api`/REST is necessary to detect policy drift quickly.

## Key Findings

### Recommended Stack

Use GitHub branch protection/rulesets as enforcement, GitHub Actions check contexts as merge gates, and `gh api` + `jq` for policy verification. Keep API calls version-pinned and verify check names after any workflow rename.

**Core technologies:**
- GitHub branch protection / rulesets: policy enforcement surface.
- GitHub Actions checks: required status checks contract.
- GitHub REST API + GitHub CLI: reproducible governance verification.

### Expected Features

**Must have (table stakes):**
- Protected branch scope for `master` and `release/**`.
- Required checks pinned to:
  - `runtime-reliability / syntax-checks`
  - `runtime-reliability / shell-regression-suite`
  - `runtime-reliability / secret-scan`
- PR review governance and required conversation resolution.
- Least-privilege direct-push/force-push exceptions.
- Reproducible verification and emergency reconciliation procedure.

**Defer (v1.2):**
- CI depth expansion (`shellcheck`/multi-OS matrix).
- Broader post-start operational hardening docs.
- Contributor evidence-capture enhancements.

### Architecture Approach

Use a three-layer model: policy contract docs (`PROJECT/REQUIREMENTS/ROADMAP`), enforcement layer (GitHub rules and required checks), and verification layer (`gh api` readback and reconciliation checklist). Each requirement should map to one phase to keep ownership clear.

### Critical Pitfalls

1. **Required-check name drift** — lock check names and verify after workflow changes.
2. **Branch pattern mis-targeting** — validate `master` and `release/**` coverage explicitly.
3. **Bypass scope creep** — use least privilege and documented exception rationale.
4. **Missing post-incident reconciliation** — require closeout checklist for emergency changes.

## Implications for Roadmap

### Phase 5: Branch Protection Policy Contract
**Rationale:** Governance enforcement must be clearly defined before verification and exception workflows.
**Delivers:** Target branch scope, required-check matrix, PR review/conversation governance contract.
**Addresses:** `GOV-01`, `GOV-02`, `GOV-03`.
**Avoids:** Name drift and branch-pattern ambiguity.

### Phase 6: Governance Verification & Exceptions
**Rationale:** Once policy is defined, ensure it is auditable and resilient during incidents.
**Delivers:** Verification procedure and emergency exception/reconciliation policy.
**Addresses:** `GOV-04`, `AUD-01`, `AUD-02`.
**Avoids:** Bypass creep and unreconciled emergency policy drift.

### Phase Ordering Rationale

- Policy contract first, verification second.
- Prevent ambiguous ownership by mapping each requirement to exactly one phase.
- Keep v1.1 policy-only and defer broader reliability expansion to v1.2.

### Research Flags

Phases likely needing deeper research during planning:
- **Phase 5:** Rulesets vs branch-rule overlap behavior in this repo's org settings.
- **Phase 6:** Practical audit command set that works for both UI and CLI users.

Phases with standard patterns (low research risk):
- **Phase 5:** Required-check and review settings are well documented in GitHub docs.

## Confidence Assessment

| Area | Confidence | Notes |
|------|------------|-------|
| Stack | HIGH | Directly supported by current GitHub docs and repo state |
| Features | HIGH | Scope and required checks are explicit and bounded |
| Architecture | HIGH | Three-layer contract/enforcement/verification model maps cleanly |
| Pitfalls | HIGH | Common failure modes are well documented and observable |

**Overall confidence:** HIGH

### Gaps to Address

- Confirm final policy implementation surface (branch rules vs rulesets) based on org/admin capabilities.
- Validate exact verification command set with current repository permissions.

## Sources

### Primary (HIGH confidence)
- https://docs.github.com/articles/about-required-reviews-for-pull-requests
- https://docs.github.com/en/repositories/configuring-branches-and-merges-in-your-repository/managing-protected-branches/managing-a-branch-protection-rule
- https://docs.github.com/repositories/configuring-branches-and-merges-in-your-repository/managing-rulesets/about-rulesets
- https://docs.github.com/repositories/configuring-branches-and-merges-in-your-repository/managing-rulesets/available-rules-for-rulesets
- https://docs.github.com/en/enterprise-cloud@latest/rest/branches/branch-protection

---
*Research completed: 2026-02-25*
*Ready for roadmap: yes*
