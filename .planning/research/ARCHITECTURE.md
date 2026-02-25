# Architecture Research

**Domain:** GitHub governance policy architecture
**Researched:** 2026-02-25
**Confidence:** HIGH

## Standard Architecture

### System Overview

```text
┌─────────────────────────────────────────────────────────────┐
│ Policy Contract Layer                                        │
├─────────────────────────────────────────────────────────────┤
│  PROJECT.md / REQUIREMENTS.md / ROADMAP.md                   │
│  - Branch targets                                             │
│  - Required checks                                            │
│  - Review and exception rules                                 │
├─────────────────────────────────────────────────────────────┤
│ Enforcement Layer                                             │
├─────────────────────────────────────────────────────────────┤
│  GitHub Branch Protection + Rulesets                          │
│  Runtime Reliability workflow check outputs                   │
├─────────────────────────────────────────────────────────────┤
│ Verification & Audit Layer                                    │
├─────────────────────────────────────────────────────────────┤
│  gh api / REST API readback / runbook checks                  │
│  exception + reconciliation procedure                          │
└─────────────────────────────────────────────────────────────┘
```

### Component Responsibilities

| Component | Responsibility | Typical Implementation |
|-----------|----------------|------------------------|
| Policy docs | Define intent and exact governance requirements | `.planning/PROJECT.md`, `.planning/REQUIREMENTS.md`, `.planning/ROADMAP.md` |
| Workflow checks | Emit required statuses for merge gating | `.github/workflows/runtime-reliability-gates.yml` |
| GitHub rules config | Enforce merge/push/review behavior | Branch protection rules and/or repository rulesets |
| Audit scripts/commands | Verify settings align with policy contract | `gh api` and `jq` checks documented in runbook/planning artifacts |

## Recommended Project Structure (for governance artifacts)

```text
.planning/
├── PROJECT.md
├── REQUIREMENTS.md
├── ROADMAP.md
├── STATE.md
├── research/
│   ├── STACK.md
│   ├── FEATURES.md
│   ├── ARCHITECTURE.md
│   ├── PITFALLS.md
│   └── SUMMARY.md
└── milestones/
    └── v1.0-research/
```

## Architectural Patterns

### Pattern 1: Policy-As-Contract

**What:** Treat branch governance decisions as explicit REQ IDs and phase deliverables.
**When to use:** Any repo where check enforcement must be auditable and reproducible.
**Trade-offs:** More documentation overhead, lower ambiguity.

### Pattern 2: Read-After-Write Verification

**What:** After setting governance policies, immediately query GitHub API/CLI and compare to contract.
**When to use:** Required-check changes, review-rule edits, bypass updates.
**Trade-offs:** Extra operational step, but catches silent drift.

### Pattern 3: Least-Privilege Bypass

**What:** Minimize bypass actors; prefer pull-request-only bypass where supported.
**When to use:** Emergency access design and admin exception paths.
**Trade-offs:** Slightly slower emergency flow, significantly better audit trail.

## Data Flow

### Merge Decision Flow

```text
Pull Request Opened
    ↓
GitHub Actions jobs run
    ↓
Status checks published (syntax-checks, shell-regression-suite, secret-scan)
    ↓
Branch protection/ruleset evaluates:
  - required checks
  - approvals
  - conversation resolution
  - push restrictions
    ↓
Merge allowed or blocked
```

### Governance Verification Flow

```text
Policy configured (UI/API)
    ↓
gh api readback for target branches / rulesets
    ↓
jq assertions against contract values
    ↓
Pass: governance aligned | Fail: drift remediation required
```

## Integration Points

### External Services

| Service | Integration Pattern | Notes |
|---------|---------------------|-------|
| GitHub Settings UI | Manual rule/ruleset creation and edits | Primary admin surface |
| GitHub REST API | Programmatic readback for protection/ruleset state | Pin API version for stability |
| GitHub Actions | Provides check contexts consumed by protection rules | Job-name stability is mandatory |

### Internal Boundaries

| Boundary | Communication | Notes |
|----------|---------------|-------|
| Planning docs ↔ repository settings | Human policy mapping + verification checklist | Keep one-to-one mapping to REQ IDs |
| Workflow checks ↔ required-check contract | Check name string matching | Any rename requires policy update |

## Sources

- https://docs.github.com/articles/about-required-reviews-for-pull-requests
- https://docs.github.com/en/repositories/configuring-branches-and-merges-in-your-repository/managing-protected-branches/managing-a-branch-protection-rule
- https://docs.github.com/repositories/configuring-branches-and-merges-in-your-repository/managing-rulesets/about-rulesets
- https://docs.github.com/en/enterprise-cloud@latest/rest/branches/branch-protection

---
*Architecture research for: branch protection governance*
*Researched: 2026-02-25*
