# Phase 2: Startup Determinism and Diagnostics - Context

**Gathered:** 2026-02-25
**Status:** Ready for planning

<domain>
## Phase Boundary

This phase hardens startup determinism for the existing launcher and container entrypoint by making validation, sequencing, readiness checks, and failure reporting consistently actionable. Scope is limited to startup contract behavior and diagnostic clarity; it does not add new runtime features or orchestration layers.

</domain>

<decisions>
## Implementation Decisions

### Runtime control validation contract
- Launcher-side validation must fail fast before Docker build/run when runtime control values are malformed.
- Port controls must be validated as integer range `1..65535` for all startup-critical port keys.
- Boolean controls must accept only `true`/`false` (case-insensitive input allowed, normalized to lowercase before use).

### Deterministic startup sequencing
- Entrypoint sequence is fixed: start teamserver, wait for teamserver TLS readiness, then start `csrestapi`, then wait for REST HTTPS health.
- `csrestapi` must never start before teamserver TLS readiness succeeds.
- Startup waits remain bounded with explicit timeout paths and failure reasons.

### Failure semantics and diagnosis
- Any unexpected process exit during startup gates must return non-zero exit status.
- Failure messages must identify which startup phase failed and which process caused the failure.
- Logs should retain actionable host/port context for probe failures without exposing secret values.

### Startup phase markers
- Startup logs should use a consistent marker scheme per phase (preflight, teamserver launch, teamserver readiness, rest launch, rest readiness, steady-state monitor).
- Success and failure lines should share stable prefixes to make operator triage and log-grep deterministic.
- Marker language should be concise and operationally specific.

### Health verification contract
- README verification commands remain `curl` HTTPS health check plus `openssl s_client` TLS probe.
- Verification guidance should match implemented defaults and explicitly call out expected status-code behavior.
- Commands should be copy-pasteable for default local deployment and still valid when `REST_API_PUBLISH_PORT` is overridden.

### Claude's Discretion
- Exact marker text, helper function naming, and formatting details.
- Minor refactoring in launcher/entrypoint to reduce duplicated validation and readiness logic.
- Documentation wording style as long as verification commands and contract semantics stay aligned.

</decisions>

<specifics>
## Specific Ideas

- Keep the canonical one-command operator flow (`./cobalt-docker.sh`) unchanged.
- Favor deterministic diagnostics over verbose logging noise.
- Keep startup diagnostics explicit enough for fast "what failed, where, and why" triage.

</specifics>

<deferred>
## Deferred Ideas

- Structured JSON logging and external log shipping are deferred to later phases.
- Automatic restart/supervision policies beyond current container lifecycle are deferred.
- Expanded multi-environment startup profiles are deferred.

</deferred>

---
*Phase: 02-startup-determinism-and-diagnostics*
*Context gathered: 2026-02-25*
