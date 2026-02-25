# Stack Research

**Domain:** GitHub branch protection and repository governance policy
**Researched:** 2026-02-25
**Confidence:** HIGH

## Recommended Stack

### Core Technologies

| Technology | Version | Purpose | Why Recommended |
|------------|---------|---------|-----------------|
| GitHub branch protection rules | Current GitHub Cloud behavior | Enforce per-branch merge and push constraints | Native control surface for required checks, review gates, and conversation resolution |
| GitHub rulesets | Current GitHub Cloud behavior | Apply reusable branch targeting + bypass policy | Better governance scale than isolated one-off branch rules |
| GitHub Actions status checks | Existing workflow checks | Supply required checks consumed by branch protection | Already implemented in repo and stable check names exist |
| GitHub REST API (versioned) | `2022-11-28` | Machine-verifiable readback of branch protection/rulesets | Enables reproducible audit and drift detection |

### Supporting Libraries / Tools

| Library/Tool | Version | Purpose | When to Use |
|--------------|---------|---------|-------------|
| GitHub CLI (`gh`) | 2.87.3 | Query and verify protection/ruleset state from terminal | Day-to-day operator verification and runbook commands |
| `jq` | 1.6+ | Normalize API JSON for deterministic checks | Audit scripts and policy assertions |
| `curl` | 7.8x+ | Raw REST fallback if `gh` abstraction is insufficient | Explicit API version pinning and troubleshooting |

### Development Tools

| Tool | Purpose | Notes |
|------|---------|-------|
| `gh api` | Retrieve branch protection + rulesets | Works with scoped token, keeps output scriptable |
| GitHub repository settings UI | Authoritative policy editing surface | Useful for initial setup and visual confirmation |
| `.planning` docs | Persist policy contract decisions | Keeps implementation and governance intent aligned |

## Installation / Access Prerequisites

```bash
# Verify CLI availability
gh --version
jq --version

# Verify authenticated GitHub access
gh auth status -h github.com
```

## Alternatives Considered

| Recommended | Alternative | When to Use Alternative |
|-------------|-------------|-------------------------|
| Rulesets + branch protection alignment | Branch protection rules only | Small repos with minimal policy complexity |
| CLI/API verification | Manual UI-only verification | One-time checks where automation is not required |

## What NOT to Use

| Avoid | Why | Use Instead |
|-------|-----|-------------|
| Non-unique check names across workflows | Can produce ambiguous required-check outcomes | Keep unique job names and pin exact required-check strings |
| Ad-hoc admin bypass as default path | Breaks governance guarantees and auditability | Explicit bypass list with pull-request-only behavior where possible |
| Unversioned API calls | Can drift with API behavior changes | Pin `X-GitHub-Api-Version: 2022-11-28` |

## Stack Patterns by Variant

**If repository policy remains simple:**
- Use branch protection rules directly for `master` and `release/**`.
- Keep required checks and review gates synchronized with workflow job names.

**If policy complexity grows across many branches/repos:**
- Use rulesets as primary policy layer, with explicit include/exclude patterns and bypass controls.
- Keep branch protection/rulesets readback in scripted audit checks.

## Sources

- https://docs.github.com/articles/about-required-reviews-for-pull-requests
- https://docs.github.com/en/repositories/configuring-branches-and-merges-in-your-repository/managing-protected-branches/managing-a-branch-protection-rule
- https://docs.github.com/repositories/configuring-branches-and-merges-in-your-repository/managing-rulesets/about-rulesets
- https://docs.github.com/repositories/configuring-branches-and-merges-in-your-repository/managing-rulesets/available-rules-for-rulesets
- https://docs.github.com/en/enterprise-cloud@latest/rest/branches/branch-protection

---
*Stack research for: branch protection governance*
*Researched: 2026-02-25*
