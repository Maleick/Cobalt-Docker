# Cobalt-Docker Runtime Hardening

## What This Is

Cobalt-Docker is an operator-focused deployment repository for running Cobalt Strike 4.12 in Docker with startup safety defaults and deterministic runtime behavior. The repository centers on `cobalt-docker.sh` and `docker-entrypoint.sh`, with validated contracts for configuration preflight, startup sequencing, mount behavior, and health verification.

## Core Value

A licensed operator can start the stack safely and predictably with one command, and failures are explicit, diagnosable, and recoverable.

## Current State

- **Latest shipped milestone:** v1.0 Runtime Hardening (2026-02-25)
- **Runtime contract:** strict `.env` required-key and control-value validation
- **Startup contract:** deterministic teamserver -> REST startup with explicit `STARTUP[...]` phase markers
- **Resilience contract:** deterministic bind/fallback mount selection and profile source diagnostics
- **Quality contract:** shell regression suite for preflight/mount/startup behavior and PR CI enforcement workflow
- **Operator docs:** canonical troubleshooting guidance in `docs/TROUBLESHOOTING.md`

## Current Milestone: v1.1 Branch Protection Governance

**Goal:** Define and operationalize protected-branch and required-check governance so repository policy enforcement is explicit, auditable, and reproducible.

**Target features:**
- Branch protection policy contract for `master` and `release/**`
- Required-check contract aligned to runtime reliability workflow checks
- Governance verification and exception/recovery procedure

## Next Milestone Goals (Deferred to v1.2)

- [ ] Expand CI reliability depth (optional `shellcheck` policy and/or multi-OS validation)
- [ ] Add post-start operational hardening documentation beyond Phase 4 runbook scope
- [ ] Improve contributor evidence-capture flow for policy compliance and audit trails

## Requirements

### Validated

- ✓ Required `.env` preflight for license/password and strict runtime control validation — v1.0
- ✓ Deterministic startup sequencing and readiness/liveness failure semantics — v1.0
- ✓ Deterministic mount/platform branching with explicit operator diagnostics — v1.0
- ✓ Secret-hygiene scanning for docs/planning artifacts — v1.0
- ✓ Shell regression suite coverage for preflight, mount, and startup branches — v1.0
- ✓ PR CI reliability gates and canonical troubleshooting runbook coverage — v1.0

### Active

- [ ] Define branch protection contract for protected targets and required checks
- [ ] Document governance rules for approvals, stale review behavior, and conversation resolution
- [ ] Define least-privilege policy for direct-push and force-push exceptions
- [ ] Create reproducible governance verification and emergency reconciliation procedure

### Out of Scope

- Unauthorized, malicious, or non-licensed Cobalt Strike usage flows
- Replacing Cobalt Strike binaries/services with custom control-plane components
- Runtime feature expansion not needed for governance policy milestone

## Context

v1.0 delivered runtime reliability and CI check implementation in-repo; the remaining gap is governance policy enforcement at repository settings/protected-branch level. This milestone intentionally constrains scope to policy contracts and verification procedures, while deferring broader CI depth and additional ops documentation to v1.2.

## Constraints

- **Security**: Never expose secret values in code, docs, logs, or planning artifacts.
- **Compatibility**: Preserve canonical launcher workflow unless explicitly versioned.
- **Platform**: Maintain Linux/macOS viability across Docker host variability.
- **Documentation**: Update README/AGENTS/runbook with behavior changes in the same change set.
- **Scope discipline**: v1.1 covers governance policy only; deferred improvements stay out of milestone scope.

## Key Decisions

| Decision | Rationale | Outcome |
|----------|-----------|---------|
| Initialize with `$gsd-new-project --auto` workflow | Establish consistent planning scaffold before implementation | ✓ Good |
| Keep planning docs committed to git | Preserve durable execution history and traceability | ✓ Good |
| Keep REST API localhost-scoped by default | Minimize accidental remote exposure risk | ✓ Good |
| Standardize deterministic `STARTUP[...]` markers | Enable reliable operator and test diagnostics | ✓ Good |
| Use shell regression specs as baseline contract safety net | Provide dependency-light reproducible verification | ✓ Good |
| Enforce runtime reliability checks in dedicated PR workflow | Make contract verification continuous and fork-safe | ✓ Good |
| Keep troubleshooting canonical in `docs/TROUBLESHOOTING.md` | Ensure one source of truth for operator/contributor triage | ✓ Good |
| Split v1.1 and v1.2 scope | Keep governance policy decisions isolated from broader operational expansion | ✓ Good |
| Set v1.1 to branch protection governance only | Lock immediate milestone intent and avoid mixed-scope roadmap drift | ✓ Good |

---
*Last updated: 2026-02-25 after v1.1 milestone start*
