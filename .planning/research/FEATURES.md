# Feature Research

**Domain:** Repository governance and merge policy enforcement
**Researched:** 2026-02-25
**Confidence:** HIGH

## Feature Landscape

### Table Stakes (Users Expect These)

| Feature | Why Expected | Complexity | Notes |
|---------|--------------|------------|-------|
| Protect `master` and release branches | Prevent unreviewed or accidental direct changes to production paths | LOW | Use branch patterns (`master`, `release/**`) |
| Require explicit status checks | Ensure CI gates block merges when contracts fail | LOW | Required check names must match workflow job names exactly |
| Require pull-request approvals | Enforce review governance before merge | LOW | Approval count + stale review behavior should be explicit |
| Require conversation resolution | Prevent merging unresolved review threads | LOW | Native branch protection option |
| Restrict force-push/direct-push | Protect branch history and prevent bypass by default | MEDIUM | Bypass scope should be minimal and intentional |

### Differentiators (Governance Maturity)

| Feature | Value Proposition | Complexity | Notes |
|---------|-------------------|------------|-------|
| Pull-request-only bypass model | Enables emergency action while preserving review/audit trail | MEDIUM | Prefer this over blanket always-bypass |
| Repeatable CLI/API verification flow | Makes policy drift visible and auditable | MEDIUM | Use `gh api` + pinned API version + scripted assertions |
| Explicit exception/recovery checklist | Reduces confusion during incidents | MEDIUM | Must include post-incident reconciliation steps |

### Anti-Features (Commonly Requested, Often Problematic)

| Feature | Why Requested | Why Problematic | Alternative |
|---------|---------------|-----------------|-------------|
| "Admins can always bypass everything" | Faster merges in the moment | Erodes policy guarantees, weakens audit confidence | Scoped bypass + documented emergency path |
| Optional/unspecified required checks | Avoids short-term CI friction | Creates policy ambiguity and merge inconsistency | Pin exact required checks and keep names stable |
| Expanding milestone to include unrelated runtime work | Feels efficient to batch changes | Breaks scope discipline and slows governance delivery | Keep v1.1 policy-only, defer to v1.2 |

## Feature Dependencies

```text
Protected branch targeting
    └──requires──> Required checks contract
                         └──requires──> Stable workflow job names

Review governance rules
    └──requires──> PR-only merge path
                         └──supports──> Exception and reconciliation policy

Verification procedure
    └──requires──> API/CLI readback endpoints
```

## MVP Definition (v1.1)

### Launch With (v1.1)

- [x] Protected branch scope for `master` and `release/**`
- [x] Required-check contract pinned to runtime reliability jobs
- [x] PR review/merge governance rules documented
- [x] Least-privilege direct-push/force-push exception policy
- [x] Reproducible verification procedure (CLI/UI)
- [x] Emergency exception + reconciliation checklist

### Add After Validation (v1.2)

- [ ] CI depth expansion (`shellcheck` policy and/or multi-OS matrix)
- [ ] Broader post-start operational hardening docs
- [ ] Contributor evidence-capture enhancements for policy audits

## Feature Prioritization Matrix

| Feature | User Value | Implementation Cost | Priority |
|---------|------------|---------------------|----------|
| Protected scope + required checks | HIGH | LOW | P1 |
| Review/conversation governance | HIGH | LOW | P1 |
| Least-privilege exception policy | HIGH | MEDIUM | P1 |
| Verification and reconciliation playbook | HIGH | MEDIUM | P1 |
| CI depth expansion | MEDIUM | MEDIUM | P2 |

## Sources

- https://docs.github.com/articles/about-required-reviews-for-pull-requests
- https://docs.github.com/en/repositories/configuring-branches-and-merges-in-your-repository/managing-protected-branches/managing-a-branch-protection-rule
- https://docs.github.com/en/repositories/configuring-branches-and-merges-in-your-repository/managing-rulesets/creating-rulesets-for-a-repository
- https://docs.github.com/repositories/configuring-branches-and-merges-in-your-repository/managing-rulesets/available-rules-for-rulesets

---
*Feature research for: branch protection governance*
*Researched: 2026-02-25*
