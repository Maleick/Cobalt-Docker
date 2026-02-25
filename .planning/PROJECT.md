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

## Next Milestone Goals

- [ ] Decide and implement branch-protection strategy for required CI checks (policy/governance layer)
- [ ] Expand CI reliability depth (for example optional `shellcheck` and/or multi-OS validation)
- [ ] Add targeted operational hardening docs for post-start lifecycle tasks
- [ ] Continue reducing ambiguity in contributor workflows and verification evidence capture

## Requirements

### Validated

- ✓ Required `.env` preflight for license/password and strict runtime control validation — v1.0
- ✓ Deterministic startup sequencing and readiness/liveness failure semantics — v1.0
- ✓ Deterministic mount/platform branching with explicit operator diagnostics — v1.0
- ✓ Secret-hygiene scanning for docs/planning artifacts — v1.0
- ✓ Shell regression suite coverage for preflight, mount, and startup branches — v1.0
- ✓ PR CI reliability gates and canonical troubleshooting runbook coverage — v1.0

### Active

- [ ] Define post-v1.0 requirement set for next milestone
- [ ] Expand CI policy from in-repo workflow enforcement to organization/repo protection configuration
- [ ] Assess additional static/runtime verification depth against maintenance cost

### Out of Scope

- Unauthorized, malicious, or non-licensed Cobalt Strike usage flows
- Replacing Cobalt Strike binaries/services with custom control-plane components
- Unrelated product expansion outside deployment/runtime reliability objectives

## Context

The v1.0 milestone completed all planned phases and requirements with a full planning/verification trail under `.planning/`. The codebase now has both operational guardrails and CI enforcement for core runtime behaviors. The immediate next step is opening a new milestone with explicit goals rather than extending v1 scope ad hoc.

## Constraints

- **Security:** never expose secret values in code, docs, logs, or planning artifacts.
- **Compatibility:** preserve canonical launcher workflow unless explicitly versioned.
- **Platform:** maintain Linux/macOS viability across Docker host variability.
- **Documentation:** update README/AGENTS/runbook with behavior changes in the same change set.
- **Scope discipline:** each new capability should enter through milestone requirements and roadmap phases.

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

---
*Last updated: 2026-02-25 after v1.0 milestone completion*
