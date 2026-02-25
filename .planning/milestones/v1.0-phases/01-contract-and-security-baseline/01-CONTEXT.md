# Phase 1: Contract and Security Baseline - Context

**Gathered:** 2026-02-25
**Status:** Ready for planning

<domain>
## Phase Boundary

This phase defines and hardens the baseline contracts for configuration and security in the existing Cobalt-Docker runtime. Scope is limited to required config behavior, secret-safe handling, secure default exposure, and documentation alignment for those contracts. It does not add new runtime capabilities beyond this boundary.

</domain>

<decisions>
## Implementation Decisions

### Configuration contract clarity
- Required keys remain exactly `COBALTSTRIKE_LICENSE` and `TEAMSERVER_PASSWORD` and must hard-fail when missing/empty.
- Optional keys should continue to receive explicit defaults, with invalid values rejected early and clearly.
- `.env` bootstrap path must remain documented and reproducible from a maintained template file.

### Secret-safe behavior
- Script output and docs must never print raw secret values.
- Generated planning/docs artifacts should be scanned for secret-like patterns before commit.
- Troubleshooting guidance must use redacted examples only.

### Secure default exposure
- REST API publish mapping remains localhost-scoped by default.
- Any broader exposure must be explicit operator intent, not implicit default behavior.
- Security-sensitive defaults are prioritized over convenience when tradeoffs appear.

### Documentation contract alignment
- Runtime behavior changes in this phase require same-phase updates to `README.md` and `AGENTS.md`.
- Validation commands shown in docs should match actual supported commands.
- Contract wording should be concise and operationally actionable.

### Claude's Discretion
- Exact formatting/layout of validation and warning messages.
- Internal organization of checks across launcher vs entrypoint as long as boundary contracts remain intact.
- Exact wording/style of documentation updates while preserving the fixed contract semantics.

</decisions>

<specifics>
## Specific Ideas

- Keep one-command operator flow (`./cobalt-docker.sh`) as the canonical path.
- Preserve fail-fast behavior over permissive startup when configuration is incomplete or invalid.
- Treat secret-safety and contract clarity as mandatory gate criteria for this phase.

</specifics>

<deferred>
## Deferred Ideas

- Multi-environment deployment overlays and advanced observability integration are deferred to later phases.
- Broader platform matrix expansion beyond baseline checks is deferred to subsequent phases.

</deferred>

---
*Phase: 01-contract-and-security-baseline*
*Context gathered: 2026-02-25*
