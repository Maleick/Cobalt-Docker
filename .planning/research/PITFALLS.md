# Pitfalls Research

**Domain:** Branch protection governance policy rollout
**Researched:** 2026-02-25
**Confidence:** HIGH

## Critical Pitfalls

### Pitfall 1: Required-Check Name Drift

**What goes wrong:**
Policy requires check names that no longer match workflow jobs, causing merges to block unexpectedly.

**Why it happens:**
Workflow job names are changed without updating branch protection/ruleset required checks.

**How to avoid:**
Treat check names as contract values; any rename must include policy + docs update.

**Warning signs:**
PRs show missing required check despite green workflow run.

**Phase to address:**
Phase 5 (policy baseline and branch/check matrix).

---

### Pitfall 2: Pattern Targeting Mistakes

**What goes wrong:**
Protection intended for release branches does not apply (or applies too broadly) due to branch pattern mistakes.

**Why it happens:**
`release/**` targeting and include/exclude rules are not validated against actual branch naming.

**How to avoid:**
Explicitly document branch patterns and verify effective coverage on representative branch names.

**Warning signs:**
A release branch accepts direct push or unreviewed merge unexpectedly.

**Phase to address:**
Phase 5 (policy baseline and targeting contract).

---

### Pitfall 3: Bypass Scope Creep

**What goes wrong:**
Too many actors can bypass governance controls, undermining enforcement.

**Why it happens:**
Emergency exceptions become permanent defaults; bypass list not reviewed.

**How to avoid:**
Define least-privilege bypass policy and review cadence; prefer PR-only bypass where available.

**Warning signs:**
Frequent merges occur through bypass path without documented incident context.

**Phase to address:**
Phase 6 (exceptions and reconciliation workflow).

---

### Pitfall 4: No Reconciliation After Emergency Changes

**What goes wrong:**
Policy is temporarily loosened during incident response and never restored.

**Why it happens:**
No explicit post-incident checklist or owner assignment.

**How to avoid:**
Require emergency change ticket + reconciliation checklist with explicit closeout verification.

**Warning signs:**
Protection settings differ from documented contract days after incident.

**Phase to address:**
Phase 6 (verification and exception recovery).

## Technical Debt Patterns

| Shortcut | Immediate Benefit | Long-term Cost | When Acceptable |
|----------|-------------------|----------------|-----------------|
| Manual UI-only setup with no readback script | Fast initial setup | Drift is hard to detect | Initial bootstrap only; must follow with verification commands |
| Broad admin bypass | Unblocks urgent merge quickly | Weak governance posture and unclear audit trail | Incident-only, time-bounded, reconciled immediately |
| Unscoped review requirements | Fewer up-front decisions | Policy confusion across branches | Never for protected production branches |

## Integration Gotchas

| Integration | Common Mistake | Correct Approach |
|-------------|----------------|------------------|
| Branch protection + Actions | Required checks set to outdated names | Pin current job names and verify after workflow edits |
| Rulesets + branch rules | Conflicting rules with unclear precedence | Document single source of truth for each target branch set |
| CLI/API verification | Missing API-version header assumptions | Use versioned API patterns consistently |

## Security Mistakes

| Mistake | Risk | Prevention |
|---------|------|------------|
| Allowing force push broadly | History rewrite and unreviewed content injection | Default block force push; use explicit limited exceptions |
| Allowing direct push to protected branches | Bypasses review and CI gates | Restrict push rights and require PR flow |
| Not requiring conversation resolution | Known concerns merged unresolved | Enable required conversation resolution |

## "Looks Done But Isn't" Checklist

- [ ] **Protected branches defined:** verify both `master` and `release/**` are covered.
- [ ] **Required checks configured:** verify exact names match workflow outputs.
- [ ] **Review rules configured:** verify approval count + stale-review behavior.
- [ ] **Bypass policy defined:** verify least-privilege actor list and rationale.
- [ ] **Emergency workflow documented:** verify reconciliation steps and ownership.

## Pitfall-to-Phase Mapping

| Pitfall | Prevention Phase | Verification |
|---------|------------------|--------------|
| Required-check name drift | Phase 5 | Compare required checks with workflow job names |
| Pattern targeting mistakes | Phase 5 | Validate branch pattern coverage on representative branches |
| Bypass scope creep | Phase 6 | Review bypass list against least-privilege policy |
| Missing reconciliation | Phase 6 | Confirm emergency checklist and closeout evidence |

## Sources

- https://docs.github.com/articles/about-required-reviews-for-pull-requests
- https://docs.github.com/en/repositories/configuring-branches-and-merges-in-your-repository/managing-protected-branches/managing-a-branch-protection-rule
- https://docs.github.com/repositories/configuring-branches-and-merges-in-your-repository/managing-rulesets/creating-rulesets-for-a-repository
- https://docs.github.com/repositories/configuring-branches-and-merges-in-your-repository/managing-rulesets/available-rules-for-rulesets

---
*Pitfalls research for: branch protection governance*
*Researched: 2026-02-25*
