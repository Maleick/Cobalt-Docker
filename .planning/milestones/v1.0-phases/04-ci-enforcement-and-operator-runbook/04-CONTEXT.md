# Phase 4: CI Enforcement and Operator Runbook - Context

**Gathered:** 2026-02-25
**Status:** Ready for planning

<domain>
## Phase Boundary

This phase enforces existing runtime reliability checks in pull-request CI and ships a dedicated troubleshooting runbook for operators and contributors. Scope is limited to CI gating for current checks and documentation coverage for startup, mount fallback, and health diagnostics. It does not add new runtime capabilities or automate branch-protection settings.

</domain>

<decisions>
## Implementation Decisions

### CI trigger scope
- Use a dedicated reliability workflow (separate from Gemini workflows).
- Trigger only on `pull_request`.
- Gate pull requests targeting `master` and `release/**`.
- Fork pull requests must run read-only checks with no secrets.

### CI gate contents
- All checks are blocking (no non-blocking informational checks).
- Required jobs:
  - syntax checks: `bash -n cobalt-docker.sh` and `bash -n docker-entrypoint.sh`
  - shell regression suite: `./tests/run-shell-tests.sh`
  - secret scan: `./scripts/scan-secrets.sh .`
- Runner baseline: `ubuntu-latest`.
- Concurrency policy: cancel in-progress runs for the same PR/ref.

### Runbook structure
- Canonical runbook path: `docs/TROUBLESHOOTING.md`.
- README must link to the runbook as the troubleshooting source of truth.
- Required runbook sections:
  - startup troubleshooting,
  - mount fallback/profile source troubleshooting,
  - health verification troubleshooting,
  - CI failure triage.
- Use `Symptom -> Checks -> Fix commands` format.
- Include a top-level quick validation command block.

### Scope guardrails
- No branch-protection automation or GitHub settings mutation in this phase.
- No expansion into a general operations handbook beyond the required Phase 4 troubleshooting coverage.
- Reuse existing checks/tools rather than introducing new static-analysis dependencies.

### Claude's Discretion
- Exact workflow/job naming details while preserving required check semantics.
- Exact wording and command presentation style in the runbook.
- Minor docs restructuring to keep links and troubleshooting navigation clear.

</decisions>

<specifics>
## Specific Ideas

- Keep CI checks reproducible locally with the same commands listed in runbook and workflow steps.
- Keep troubleshooting commands copy-pasteable and scoped to known failure contracts from Phases 1-3.
- Make CI failure triage map directly from workflow job name to local command.

</specifics>

<deferred>
## Deferred Ideas

- Branch protection policy automation via API or admin-token flows.
- Additional static analysis tooling (for example, shellcheck policy rollout).
- Multi-OS CI matrix beyond `ubuntu-latest`.

</deferred>

---
*Phase: 04-ci-enforcement-and-operator-runbook*
*Context gathered: 2026-02-25*
