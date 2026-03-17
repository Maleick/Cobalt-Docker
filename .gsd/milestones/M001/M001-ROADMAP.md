# M001: LLM-Native REST API Skill

**Vision:** Enable LLM agents to directly authenticate and operate Cobalt Strike's full REST API surface through a pi skill — replacing the MCP server dependency with zero-infrastructure skill-native integration that auto-detects the local Docker environment and handles the full async task lifecycle.

## Success Criteria

- Agent can load the skill, authenticate to the CS REST API, and receive a bearer token without manual curl
- Agent can submit a command to a beacon, poll task status to completion, and present merged log/error results
- Curl patterns exist for all 6 core endpoint groups with lighter references for the remaining 8
- At least 4 operational playbooks document real multi-step workflows with failure handling
- Skill works for both local Docker (auto-detected from .env) and remote Team Server (user-provided)
- Gemini CI removed, Dockerfile pinned to ubuntu:24.04, COBALT_LISTENER_BIND_HOST has test coverage
- All documentation (README, AGENTS.md) reflects the skill approach
- All CI gates pass (syntax-checks, shell-regression-suite, secret-scan)

## Key Risks / Unknowns

- **Async task polling complexity** — agents may poll indefinitely or miss terminal states if the skill workflow isn't explicit enough about exit conditions
- **Spawn vs inject disambiguation** — many endpoint groups duplicate patterns; agents need clear guidance to pick the right variant
- **Token expiry mid-session** — agents must detect 401 and re-authenticate without losing operational context
- **Self-signed TLS handling** — `-k` is correct for local Docker but wrong for production remote deployments

## Proof Strategy

- Async task polling → retire in S02 by proving the skill workflow includes explicit polling loop with timeout and terminal state detection
- Spawn vs inject → retire in S03 by proving each endpoint pattern documents when to use spawn vs inject
- Token expiry → retire in S02 by proving the auth workflow includes 401 detection and re-auth recovery
- Self-signed TLS → retire in S02 by proving the skill distinguishes local (self-signed, `-k`) from remote (user-provided cert handling)

## Verification Classes

- Contract verification: bash -n syntax checks on all shell scripts, secret-scan on all new/modified files, file existence and structure checks on skill artifacts
- Integration verification: curl patterns produce valid requests against a running CS REST API (requires live instance)
- Operational verification: none (no new runtime services)
- UAT / human verification: operator loads skill in pi and follows workflow against a live CS deployment

## Milestone Definition of Done

This milestone is complete only when all are true:

- All 4 slice deliverables are complete (housekeeping, skill core, endpoint patterns, docs sync)
- Skill files load correctly in pi and provide operational guidance
- Auth workflow handles both local Docker and remote Team Server
- Async task lifecycle (submit → poll → log/error → present) is documented with explicit exit conditions
- CI gates pass: syntax-checks, shell-regression-suite, secret-scan
- README and AGENTS.md accurately describe the skill as the recommended LLM integration path
- Final integrated acceptance scenarios verified (auth + endpoint call + task tracking)

## Requirement Coverage

- Covers: R001, R002, R003, R004, R005, R006, R007, R008, R009, R010, R011, R012
- Partially covers: none
- Leaves for later: R013 (deep coverage for remaining 8 groups), R014 (runtime OpenAPI spec fetch)
- Orphan risks: none

## Slices

- [ ] **S01: Repo Housekeeping & CI Cleanup** `risk:low` `depends:[]`
  > After this: Gemini CI workflows removed, Dockerfile pinned to ubuntu:24.04, .gitignore clean, COBALT_LISTENER_BIND_HOST has shell regression test coverage, all CI gates pass.

- [ ] **S02: Operational Skill Core** `risk:high` `depends:[]`
  > After this: Agent can load the skill, auto-detect local Docker environment from .env, authenticate to the REST API via JWT, and follow the full async task lifecycle (submit → poll → log/error → present results). Verified by reading skill files and confirming workflow completeness — live API testing requires a running CS instance.

- [ ] **S03: Endpoint Patterns & Operational Playbooks** `risk:medium` `depends:[S02]`
  > After this: Curl templates exist for all 6 core endpoint groups (beacons, listeners, tasks, credentials, server config, payloads) plus lighter references for the remaining 8 groups. At least 4 operational playbooks document multi-step workflows with preconditions, steps, and failure handling.

- [ ] **S04: Documentation Sync & Validation** `risk:low` `depends:[S01,S02,S03]`
  > After this: README, AGENTS.md, and TROUBLESHOOTING.md reflect the skill approach. All docs are internally consistent with implemented behavior. Secret scan passes on all files.

## Boundary Map

### S01 → S04

Produces:
- Clean CI state (Gemini workflows removed, Dockerfile pinned)
- `COBALT_LISTENER_BIND_HOST` regression test in `tests/spec/cobalt-docker.preflight-mount.sh`
- Updated `.gitignore` with `.bg-shell/` and `.gsd/` entries

Consumes:
- nothing (housekeeping slice, no upstream deps)

### S02 → S03

Produces:
- Enhanced `SKILL.md` with operational execution mode (not just documentation)
- Auth lifecycle workflow: environment detection → token acquisition → token reuse → 401 recovery
- Async task lifecycle pattern: submit command → capture task ID → poll status → fetch log/error → present results
- Updated `references/runtime-and-auth.md` with environment detection and token renewal
- Base curl command patterns (auth header, TLS handling, base URL construction)

Consumes:
- nothing (skill core stands alone)

### S02 → S04

Produces:
- Same as S02 → S03 (skill workflow and auth patterns for documentation reference)

Consumes:
- nothing

### S03 → S04

Produces:
- `references/endpoint-patterns.md` — curl templates for 6 core groups + lighter patterns for 8 remaining groups
- `references/operational-playbooks.md` — at least 4 multi-step workflow playbooks
- Updated `references/endpoint-catalog.md` with any corrections or additions

Consumes from S02:
- Auth workflow pattern (how to construct authenticated curl commands)
- Base curl command shape (headers, TLS flags, base URL variable)
- Async task lifecycle pattern (referenced by playbooks that submit and track commands)
