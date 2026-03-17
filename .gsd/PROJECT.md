# Cobalt-Docker

## What This Is

A Docker deployment wrapper for Cobalt Strike 4.12 that provides one-command startup of the teamserver + REST API with strict `.env` preflight validation, automatic TLS readiness detection, mount fallback behavior for malleable profiles, and deterministic `STARTUP[...]` phase markers for observability. The REST API (`csrestapi`) is auto-started alongside the teamserver and published on localhost by default.

## Core Value

A licensed operator can start the stack safely and predictably with one command, and failures are explicit, diagnosable, and recoverable.

## Current State

- **v1.0 Runtime Hardening** shipped: deterministic startup sequencing, preflight validation, mount fallback, shell regression tests, CI gates (syntax-checks, shell-regression-suite, secret-scan), troubleshooting runbook.
- **v1.1 Branch Protection Governance** shipped: branch protection policy for `master` and `release/**`, governance verification procedures, exception workflow with reconciliation.
- **Active work (M001):** Adding LLM-native pi skill for direct REST API interaction — replacing MCP dependency with a skill that teaches agents to authenticate and operate the full API surface via curl.

## Architecture / Key Patterns

- **Entry point:** `./cobalt-docker.sh` — preflight validation, mount probe, Docker run orchestration
- **Container entrypoint:** `docker-entrypoint.sh` — teamserver launch → TLS readiness wait → csrestapi launch → HTTPS readiness wait → monitor
- **Startup markers:** `STARTUP[preflight]`, `STARTUP[teamserver-launch]`, `STARTUP[teamserver-ready]`, `STARTUP[rest-launch]`, `STARTUP[rest-ready]`, `STARTUP[monitor]`
- **REST API:** Published on `${REST_API_PUBLISH_BIND:-127.0.0.1}:${REST_API_PUBLISH_PORT:-50443}:50443`, JWT bearer auth, async task model
- **Tests:** Shell regression specs in `tests/spec/` covering preflight, mount, startup, and DyeDNV wizard contracts
- **CI:** GitHub Actions `runtime-reliability-gates.yml` — syntax-checks, shell-regression-suite, secret-scan
- **Skills:** `.agents/skills/cobaltstrike-rest-api/` — endpoint catalog, auth flow, agent usage patterns (currently documentation-only, being upgraded to operational)

## Capability Contract

See `.gsd/REQUIREMENTS.md` for the explicit capability contract, requirement status, and coverage mapping.

## Milestone Sequence

- [ ] M001: LLM-Native REST API Skill — Enable agents to directly authenticate and operate Cobalt Strike via pi skill instead of MCP
