# M001: LLM-Native REST API Skill

**Gathered:** 2026-03-17
**Status:** Ready for planning

## Project Description

Cobalt-Docker is a Docker deployment wrapper for Cobalt Strike 4.12. The REST API (`csrestapi`) auto-starts alongside the teamserver inside the container. An existing skill at `.agents/skills/cobaltstrike-rest-api/` provides documentation-only reference material (endpoint catalog, auth flow, agent usage patterns). This milestone upgrades that skill from documentation into a fully operational pi skill that teaches agents to directly authenticate and operate the entire REST API surface — eliminating the need for a separate MCP server process.

## Why This Milestone

The REST API was introduced in CS 4.12 specifically to enable LLM integration. Fortra published an official MCP server PoC using FastMCP. But MCP requires a separate Python process, runtime configuration, and maintenance. A pi skill eliminates that layer entirely — the agent uses curl directly through the REST API that's already running in the Docker container. The infrastructure is already there; only the skill intelligence is missing.

## User-Visible Outcome

### When this milestone is complete, the user can:

- Load the pi skill and have an agent authenticate to the CS REST API, list beacons, create listeners, dispatch commands, and track tasks to completion — all without touching curl manually or running an MCP server
- Point the same skill at a remote Team Server by providing base URL and credentials

### Entry point / environment

- Entry point: pi agent with skill loaded, running against local Docker or remote Team Server
- Environment: local dev (macOS/Linux with Docker) or remote Team Server (Linux)
- Live dependencies involved: Cobalt Strike REST API (HTTPS, port 50443), teamserver (port 50050)

## Completion Class

- Contract complete means: skill files exist with correct structure, curl patterns are syntactically valid, reference files are internally consistent
- Integration complete means: an agent can follow the skill workflow to authenticate and call real endpoints (requires running CS instance)
- Operational complete means: none (no new runtime services introduced)

## Final Integrated Acceptance

To call this milestone complete, we must prove:

- An agent loading the skill can follow the auth workflow and acquire a bearer token (verifiable against a running CS REST API)
- The skill's curl patterns for all 6 core groups produce valid requests when filled with real parameters
- All CI gates pass (syntax-checks, shell-regression-suite, secret-scan)
- Documentation (README, AGENTS.md) accurately describes the skill approach

## Risks and Unknowns

- **Async task polling complexity** — the REST API's async model (submit → poll → fetch log/error) requires clear skill guidance to prevent agents from getting confused or polling indefinitely
- **Spawn vs inject pattern duplication** — many endpoint groups have both variants; the skill must clearly explain when to use which
- **Self-signed TLS handling** — local Docker uses self-signed certs; the skill must guide agents to use `-k` without creating security anti-patterns for remote deployments
- **Token expiry mid-session** — agents need to detect 401 responses and re-authenticate; skill workflow must include this recovery path

## Existing Codebase / Prior Art

- `.agents/skills/cobaltstrike-rest-api/SKILL.md` — current skill entry point (documentation mode)
- `.agents/skills/cobaltstrike-rest-api/references/endpoint-catalog.md` — endpoint purpose documentation
- `.agents/skills/cobaltstrike-rest-api/references/runtime-and-auth.md` — auth flow, curl examples, failure modes
- `.agents/skills/cobaltstrike-rest-api/references/agent-usage-patterns.md` — 4 operational patterns (beacon inventory, task polling, listener lifecycle, evidence collection)
- `.agents/skills/cobaltstrike-rest-api/references/sources.md` — version and source tracking
- `.agents/skills/cobaltstrike-rest-api/agents/openai.yaml` — minimal OpenAI agent config
- `docker-entrypoint.sh` — REST API auto-start logic (lines ~80-120)
- `cobalt-docker.sh` — .env loading, REST API port publishing
- `.env.example` — template with REST_API_PUBLISH_PORT, REST_API_USER defaults

> See `.gsd/DECISIONS.md` for all architectural and pattern decisions — it is an append-only register; read it during planning, append to it during execution.

## Relevant Requirements

- R001 — Agent authentication via skill (core gate)
- R002 — Auto-detect local Docker from .env (zero-config UX)
- R003 — Full async task lifecycle (primary user loop)
- R004 — Core endpoint curl patterns (operational surface)
- R005 — Lighter reference patterns (completeness)
- R006 — Operational playbooks (workflow composition)
- R007 — Local Docker + remote Team Server support (deployment flexibility)
- R008-R011 — Repo housekeeping (CI, Dockerfile, tests, .gitignore)
- R012 — Documentation consistency (README, AGENTS.md)

## Scope

### In Scope

- Upgrade existing skill from documentation-only to operational execution mode
- Auto-detect environment (local Docker vs remote) from .env
- JWT auth lifecycle (acquire, reuse, renew on 401)
- Curl patterns for 6 core endpoint groups (beacons, listeners, tasks, credentials, server config, payloads)
- Lighter reference patterns for remaining 8 groups
- At least 4 operational playbooks with preconditions, steps, and failure handling
- Remove Gemini CI workflows and command configs
- Pin Dockerfile to ubuntu:24.04
- Add COBALT_LISTENER_BIND_HOST test coverage
- Fix .gitignore gaps
- Update README, AGENTS.md, TROUBLESHOOTING.md

### Out of Scope / Non-Goals

- MCP server implementation (R015)
- Unauthorized use workflows (R016)
- Cobalt Strike binary modifications (R017)
- Full deep coverage for remaining 8 endpoint groups (R013 — deferred)
- Runtime OpenAPI spec fetch (R014 — deferred)

## Technical Constraints

- REST API uses self-signed TLS certificates by default (curl requires `-k` for local Docker)
- JWT bearer tokens have configurable duration (max 86400000ms = 24h)
- Most action endpoints return async task IDs, not immediate results
- OpenAPI spec accessible at `/v3/api-docs` on running REST API (useful for future R014)
- Skill files must be under `.agents/skills/cobaltstrike-rest-api/` to match existing structure

## Integration Points

- **Cobalt Strike REST API** — HTTPS on port 50443, JWT bearer auth, OAS 3.1
- **docker-entrypoint.sh** — auto-starts csrestapi; skill depends on this being running
- **cobalt-docker.sh** — reads .env for REST_API_PUBLISH_PORT, REST_API_USER; skill reads same .env
- **pi skill system** — skill must be discoverable via SKILL.md location and description

## Open Questions

- **Polling interval for task tracking** — current thinking: 2s default with configurable override, max 60 retries (2 min ceiling)
- **How to handle binary file downloads** — current thinking: save to temp file with curl `-o`, report path to operator
