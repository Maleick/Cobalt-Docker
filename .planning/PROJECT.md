# Cobalt-Docker Runtime Hardening

## What This Is

Cobalt-Docker is an operator-focused deployment repository for running Cobalt Strike 4.12 in Docker with strong startup safety defaults. It provides a canonical launcher (`cobalt-docker.sh`) and a controlled entrypoint (`docker-entrypoint.sh`) that starts teamserver and REST API in the correct order with readiness checks. This project extends that baseline with stronger reliability, security guardrails, and testable operational contracts.

## Core Value

A licensed operator can start the stack safely and predictably with one command, and failures are explicit, diagnosable, and recoverable.

## Requirements

### Validated

- ✓ Teamserver and REST API startup sequencing is implemented with readiness gates — existing
- ✓ Required `.env` preflight for `COBALTSTRIKE_LICENSE` and `TEAMSERVER_PASSWORD` is enforced — existing
- ✓ Mount probe plus fallback behavior for daemon-invisible host paths is implemented — existing
- ✓ Runtime health validation paths (`openssl` and `curl`) are implemented — existing
- ✓ Canonical launcher workflow is established via `./cobalt-docker.sh` — existing

### Active

- [ ] Add automated regression checks for launcher and entrypoint critical branches
- [ ] Improve cross-platform runtime robustness (including host interface assumptions)
- [ ] Harden security defaults and operator guidance around secret/network handling
- [ ] Keep implementation and documentation synchronized to prevent drift
- [ ] Establish phased planning artifacts for reliable execution (`REQUIREMENTS`, `ROADMAP`, `STATE`)

### Out of Scope

- Unauthorized, malicious, or non-licensed Cobalt Strike usage flows — violates project purpose
- Replacing Cobalt Strike binaries with custom control-plane implementations — not this repo's goal
- Building unrelated product features outside deployment/runtime hardening — defer to future milestones

## Context

This repository already contains the operational runtime core and a complete codebase map under `.planning/codebase/`. The current opportunity is not greenfield feature invention; it is disciplined hardening of a working deployment path. Existing constraints include shell portability, Docker host variability (especially mount visibility on Desktop setups), and careful secret handling. The project should prioritize reliability and maintainability improvements that preserve backward-compatible operator usage.

## Constraints

- **Security**: Secrets must not appear in commits, prompts, or generated planning docs — prevents credential leakage risk
- **Compatibility**: Preserve canonical entrypoint behavior (`./cobalt-docker.sh`) unless explicitly versioned — protects operator workflows
- **Platform**: Host-side behavior must remain viable across Linux/macOS Docker environments — reduces environment-specific failures
- **Documentation**: Behavior changes require corresponding `README.md` and `AGENTS.md` updates — prevents contract drift
- **Scope**: Focus on deployment/runtime reliability and testability, not unrelated product expansion — maintains milestone discipline

## Key Decisions

| Decision | Rationale | Outcome |
|----------|-----------|---------|
| Initialize with `$gsd-new-project --auto` defaults | User requested automated project bootstrapping flow | — Pending |
| Keep planning docs committed to git | Maintain durable artifact history and reproducible phase context | — Pending |
| Use quick-depth roadmap with parallel-ready planning | Prioritize momentum while retaining structured phase decomposition | — Pending |
| Treat current codebase capabilities as validated baseline | Existing scripts already implement core startup and preflight behavior | ✓ Good |

---
*Last updated: 2026-02-25 after initialization*
