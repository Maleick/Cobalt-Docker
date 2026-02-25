# Idea: Production-Ready Cobalt-Docker Runtime and Planning Track

## One-line Vision
Make this repository the safest and most reliable way to run Cobalt Strike 4.12 with automated teamserver + REST API startup in Docker.

## Problem
Operators need a repeatable deployment flow that works across host environments (including Docker Desktop path visibility edge cases), fails early on bad config, and gives clear health signals. The current repository has strong foundations, but still lacks a complete planning baseline and automated regression coverage for critical shell logic.

## Audience
- Red team operators running licensed Cobalt Strike in controlled environments
- Security engineers maintaining teamserver infrastructure
- Contributors evolving launch/runtime behavior without breaking operational contracts

## Current State (Observed)
- Canonical launcher exists: `cobalt-docker.sh`
- In-container orchestration exists: `docker-entrypoint.sh`
- Strict `.env` preflight exists for required keys
- Mount fallback behavior exists for daemon-invisible host paths
- Teamserver + `csrestapi` ordered startup and readiness checks are implemented
- Codebase map now exists under `.planning/codebase/`

## Desired Outcome
Create a complete GSD project plan and execute it in phases to:
- harden runtime behavior,
- improve security defaults and operator guidance,
- add regression tests for launcher and entrypoint scripts,
- keep docs and implementation in lockstep.

## Goals
1. Preserve and strengthen the existing deployment contract (`./cobalt-docker.sh` as primary entrypoint).
2. Add reliable automated checks for critical script behavior (preflight, mount mode, startup sequencing, health checks).
3. Reduce configuration drift between docs, templates, and actual repository files.
4. Improve failure diagnostics so operators can recover quickly.

## In Scope (Near-term Milestones)
- Project initialization artifacts in `.planning/` (`PROJECT.md`, `REQUIREMENTS.md`, `ROADMAP.md`, `STATE.md`, `config.json`)
- Requirements and roadmap for runtime hardening and operational test automation
- Script-level validation expansion (beyond syntax checks)
- Documentation updates tied to behavioral changes

## Out of Scope
- Any attempt to bypass Cobalt Strike licensing
- Malicious or unauthorized use workflows
- Replacing Cobalt Strike core binaries/services with custom equivalents

## Table Stakes Requirements
- Required `.env` keys remain enforced: `COBALTSTRIKE_LICENSE`, `TEAMSERVER_PASSWORD`
- Teamserver starts before REST API; readiness is explicitly gated
- Mount fallback remains deterministic and clearly logged
- REST API publish behavior remains explicit and secure by default
- No secrets committed to git, docs, or generated planning artifacts

## Differentiators to Pursue
- Better automated regression coverage for shell logic and startup error paths
- Clearer operator troubleshooting runbook for common failures
- Tighter consistency checks between `README.md`, `AGENTS.md`, and runtime behavior

## Constraints
- Keep shell scripts portable across Linux and macOS host environments
- Maintain backward-compatible launcher usage patterns unless explicitly versioned
- Follow repo contract in `AGENTS.md` (including documentation updates when behavior changes)

## Risks and Unknowns
- Platform-specific networking and interface detection differences
- External dependency drift (download endpoint formats, action ecosystem changes)
- Secret-handling mistakes during maintenance if guardrails are not automated

## Success Criteria
- GSD project is initialized with clear phased roadmap
- Every critical launcher/entrypoint branch has at least one automated regression check
- Documentation accurately reflects implemented runtime behavior
- Contributors can make script changes with lower risk of operational regressions

## Initial Milestone Candidate
Milestone 1: "Runtime Reliability Baseline"
- Define acceptance tests for preflight, mount fallback, and startup health gates
- Implement test harness and CI wiring for shell behavior checks
- Close high-priority drift items between docs and runtime scripts
