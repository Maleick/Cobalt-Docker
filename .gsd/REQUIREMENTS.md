# Requirements

This file is the explicit capability and coverage contract for the project.

## Active

### R001 — Agent can authenticate to CS REST API via skill
- Class: core-capability
- Status: active
- Description: An agent loading the pi skill can acquire a JWT bearer token from `/api/auth/login` and use it for subsequent API calls
- Why it matters: Authentication is the gate to every other API operation — nothing works without it
- Source: user
- Primary owning slice: M001/S02
- Supporting slices: none
- Validation: unmapped
- Notes: Must handle both local Docker (self-signed TLS, `-k` flag) and remote Team Server (user-provided cert behavior)

### R002 — Skill auto-detects local Docker environment from .env
- Class: operability
- Status: active
- Description: When `.env` exists with `REST_API_PUBLISH_PORT` and `REST_API_USER`, the skill uses those values to construct the base URL and auth credentials without asking the operator
- Why it matters: Zero-config for the common case (local Docker) makes the skill feel native, not bolted on
- Source: user
- Primary owning slice: M001/S02
- Supporting slices: none
- Validation: unmapped
- Notes: Falls back to prompting when `.env` is absent or missing REST API keys

### R003 — Full async task lifecycle
- Class: primary-user-loop
- Status: active
- Description: Agent can submit a command, poll `GET /api/v1/tasks/{taskId}` until terminal state (`COMPLETED`/`FAILED`/`OUTPUT_RECEIVED`), fetch log and error channels, and present merged results
- Why it matters: Most REST API actions are async — without task tracking, the agent can submit commands but can't report results
- Source: user
- Primary owning slice: M001/S02
- Supporting slices: M001/S03
- Validation: unmapped
- Notes: Polling interval and timeout should be configurable in skill workflow

### R004 — Curl patterns for 6 core endpoint groups
- Class: core-capability
- Status: active
- Description: Executable curl templates for beacons, listeners, tasks, credentials, server config, and payloads — covering the primary operator workflows
- Why it matters: These 6 groups cover ~80% of operational use — an agent with these patterns can run most engagements
- Source: user
- Primary owning slice: M001/S03
- Supporting slices: none
- Validation: unmapped
- Notes: Each pattern includes method, path, headers, request body shape, and expected response shape

### R005 — Lighter reference patterns for remaining 8 groups
- Class: core-capability
- Status: active
- Description: Reference-level curl patterns (method, path, description, key parameters) for network recon, pivoting, tunneling, capture, beacon config, file/registry, process/execution, and server config detail endpoints
- Why it matters: Agents need at least a reference to attempt any endpoint, even if the pattern is lighter than core groups
- Source: user
- Primary owning slice: M001/S03
- Supporting slices: none
- Validation: unmapped
- Notes: These can be deepened in a future milestone (R013)

### R006 — Operational playbooks for common multi-step workflows
- Class: primary-user-loop
- Status: active
- Description: At least 4 documented multi-step playbooks: beacon inventory + dispatch, listener lifecycle, task tracking loop, and evidence collection pipeline
- Why it matters: Individual endpoints are building blocks — playbooks show agents how to compose them into real operational sequences
- Source: user
- Primary owning slice: M001/S03
- Supporting slices: M001/S02
- Validation: unmapped
- Notes: Each playbook includes preconditions, step sequence, failure handling, and expected outputs

### R007 — Skill works for both local Docker and remote Team Server
- Class: operability
- Status: active
- Description: The skill workflow handles both deployment modes: local Docker (localhost, self-signed TLS, .env-driven) and remote Team Server (user-provided host, port, cert behavior, credentials)
- Why it matters: Operators deploy Cobalt Strike both ways — the skill must not assume one mode
- Source: user
- Primary owning slice: M001/S02
- Supporting slices: none
- Validation: unmapped
- Notes: Remote mode requires explicit base URL, username, password, and TLS cert handling

### R008 — Remove Gemini CI workflows and command configs
- Class: operability
- Status: active
- Description: Remove all 5 Gemini GitHub Actions workflows (`gemini-dispatch.yml`, `gemini-invoke.yml`, `gemini-review.yml`, `gemini-scheduled-triage.yml`, `gemini-triage.yml`) and associated command configs
- Why it matters: Orphaned CI configurations add maintenance burden and confusion
- Source: user
- Primary owning slice: M001/S01
- Supporting slices: none
- Validation: unmapped
- Notes: Also remove `.github/commands/` directory if it becomes empty

### R009 — Pin Dockerfile base image to Ubuntu LTS
- Class: quality-attribute
- Status: active
- Description: Change `FROM ubuntu:latest` to `FROM ubuntu:24.04` for reproducible builds
- Why it matters: Unpinned base images cause non-deterministic builds and can introduce breaking changes silently
- Source: user
- Primary owning slice: M001/S01
- Supporting slices: none
- Validation: unmapped
- Notes: Ubuntu 24.04 is the current LTS; CS REST API is tested on Ubuntu 22.04 and 24.04

### R010 — Add COBALT_LISTENER_BIND_HOST test coverage
- Class: quality-attribute
- Status: active
- Description: Shell regression test covering `COBALT_LISTENER_BIND_HOST` variable handling in `cobalt-docker.sh`
- Why it matters: Recently added feature with zero test coverage — a regression could go unnoticed
- Source: inferred
- Primary owning slice: M001/S01
- Supporting slices: none
- Validation: unmapped
- Notes: Variable exists in `cobalt-docker.sh` but no test spec references it

### R011 — Fix .gitignore gaps
- Class: operability
- Status: active
- Description: Add `.bg-shell/` and `.gsd/` to `.gitignore` to prevent transient/agent state from being committed
- Why it matters: Clean git status prevents accidental commits of transient data
- Source: inferred
- Primary owning slice: M001/S01
- Supporting slices: none
- Validation: unmapped
- Notes: `.bg-shell/` already partially fixed; verify completeness

### R012 — Documentation consistency
- Class: quality-attribute
- Status: active
- Description: README, AGENTS.md, and TROUBLESHOOTING.md reflect the skill approach and current project state
- Why it matters: Stale docs mislead operators and future agents about how the system actually works
- Source: user
- Primary owning slice: M001/S04
- Supporting slices: none
- Validation: unmapped
- Notes: Should mention the skill as the recommended LLM integration path, reference the existing MCP blog posts as alternative

## Validated

(none yet)

## Deferred

### R013 — Full deep coverage for remaining 8 endpoint groups
- Class: core-capability
- Status: deferred
- Description: Promote the lighter reference patterns (R005) to full executable curl templates with playbooks for network recon, pivoting, tunneling, capture, beacon config, file/registry, process/execution
- Why it matters: Complete coverage enables agents to handle edge-case operations without improvising
- Source: user
- Primary owning slice: none
- Supporting slices: none
- Validation: unmapped
- Notes: Deferred to post-M001 — core ops first

### R014 — Runtime OpenAPI spec fetch from /v3/api-docs
- Class: differentiator
- Status: deferred
- Description: Skill can fetch the live OpenAPI spec from the running REST API at `/v3/api-docs` to validate endpoint signatures at runtime
- Why it matters: Self-validating endpoint patterns reduce drift between skill docs and actual API surface
- Source: research
- Primary owning slice: none
- Supporting slices: none
- Validation: unmapped
- Notes: Discovered during research — the spec is available at `https://teamserver:50443/v3/api-docs`

## Out of Scope

### R015 — MCP server implementation
- Class: anti-feature
- Status: out-of-scope
- Description: Building or maintaining a separate MCP server process for Cobalt Strike REST API interaction
- Why it matters: This milestone explicitly replaces MCP with a native skill approach — prevents scope creep back to MCP
- Source: user
- Primary owning slice: none
- Supporting slices: none
- Validation: n/a
- Notes: Fortra and community have published MCP servers if someone wants that path; our approach is skill-native

### R016 — Unauthorized use workflows
- Class: anti-feature
- Status: out-of-scope
- Description: Any skill patterns that facilitate unauthorized access, testing without approval, or use outside sanctioned environments
- Why it matters: Explicit boundary — the skill is for authorized red team operations only
- Source: AGENTS.md
- Primary owning slice: none
- Supporting slices: none
- Validation: n/a
- Notes: Skill includes authorized-use boundary statement

### R017 — Cobalt Strike binary modifications
- Class: constraint
- Status: out-of-scope
- Description: Any changes to Cobalt Strike binaries, teamserver internals, or csrestapi source code
- Why it matters: We wrap and configure, we don't modify the product
- Source: AGENTS.md
- Primary owning slice: none
- Supporting slices: none
- Validation: n/a
- Notes: All integration is through the published REST API surface

## Traceability

| ID | Class | Status | Primary owner | Supporting | Proof |
|---|---|---|---|---|---|
| R001 | core-capability | active | M001/S02 | none | unmapped |
| R002 | operability | active | M001/S02 | none | unmapped |
| R003 | primary-user-loop | active | M001/S02 | M001/S03 | unmapped |
| R004 | core-capability | active | M001/S03 | none | unmapped |
| R005 | core-capability | active | M001/S03 | none | unmapped |
| R006 | primary-user-loop | active | M001/S03 | M001/S02 | unmapped |
| R007 | operability | active | M001/S02 | none | unmapped |
| R008 | operability | active | M001/S01 | none | unmapped |
| R009 | quality-attribute | active | M001/S01 | none | unmapped |
| R010 | quality-attribute | active | M001/S01 | none | unmapped |
| R011 | operability | active | M001/S01 | none | unmapped |
| R012 | quality-attribute | active | M001/S04 | none | unmapped |
| R013 | core-capability | deferred | none | none | unmapped |
| R014 | differentiator | deferred | none | none | unmapped |
| R015 | anti-feature | out-of-scope | none | none | n/a |
| R016 | anti-feature | out-of-scope | none | none | n/a |
| R017 | constraint | out-of-scope | none | none | n/a |

## Coverage Summary

- Active requirements: 12
- Mapped to slices: 12
- Validated: 0
- Unmapped active requirements: 0
