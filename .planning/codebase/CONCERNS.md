# Codebase Concerns

**Analysis Date:** 2026-02-25

## Tech Debt

**Host-IP detection is interface-assumptive on macOS:**
- Issue: `cobalt-docker.sh` uses `ifconfig en0` on Darwin, which is not universal across all Mac setups.
- Why: Fast path for typical macOS laptops.
- Impact: Launch can fail to determine host IP on systems where primary interface is not `en0`.
- Fix approach: use route-based detection or parameterized host override.

**Configuration parsing duplicated and manual:**
- Issue: `.env` parsing and normalization logic is custom shell/awk code.
- Why: avoids sourcing untrusted shell content directly.
- Impact: maintainability burden and potential edge-case parsing drift.
- Fix approach: centralize parsing tests and document supported `.env` syntax strictly.

## Known Bugs / Operational Hazards

**Template drift hazard for `.env.example`:**
- Symptoms: docs and agent contract expect `.env.example`, but local worktree currently shows deletion (`git status`: `D .env.example`).
- Trigger: fresh setup attempts that rely on `cp .env.example .env` from `README.md`.
- Workaround: recreate template manually from docs.
- Root cause: repository state drift between documentation and tracked files.

**False-positive health success risk:**
- Symptoms: health probe accepts HTTP `2xx-4xx` as ready.
- Trigger: auth-protected endpoint returns `401/403` while service may still be partially misconfigured.
- Workaround: pair health check with TLS and process-liveness checks (already done).
- Root cause: readiness definition intentionally broad for auth-protected endpoints.

## Security Considerations

**License and credential handling in build/run path:**
- Risk: `COBALTSTRIKE_LICENSE` is passed as Docker build arg and `TEAMSERVER_PASSWORD` as runtime env; mishandling can leak secrets via logs/history.
- Current mitigation: `.env` is gitignored and scripts avoid echoing secret values.
- Recommendations: add explicit docs on safe Docker history handling and secret rotation procedures.

**Broad network exposure defaults:**
- Risk: container publishes `50050`, `80`, `443`, and `53/udp`; unintended exposure is possible in permissive host/network contexts.
- Current mitigation: REST API publish uses localhost host-bind by default.
- Recommendations: document firewall requirements and provide secure-by-default opt-in flags for listener exposure.

## Performance Bottlenecks

**Image build path is heavyweight:**
- Problem: each build downloads/updates Cobalt Strike and base packages.
- Measurement: no benchmark in repo; expected slow startup for first build and cache invalidations.
- Cause: build-time fetch/update model and large dependency footprint.
- Improvement path: document cache strategy and optional prebuilt image workflow.

**Startup readiness loops are serial:**
- Problem: teamserver readiness then REST API readiness are sequential with up to 60s loops each.
- Measurement: worst-case perceived startup delay can exceed one minute per phase.
- Cause: conservative polling and strict dependency ordering.
- Improvement path: surface timeout overrides and richer intermediate diagnostics.

## Fragile Areas

**Mount fallback contract (`configure_mount_mode`):**
- Why fragile: behavior shifts between bind and in-image profile modes based on daemon visibility.
- Common failures: operator expects host profile but silently uses fallback profile path.
- Safe modification: retain explicit logging and add post-start profile provenance logging.
- Test coverage: no automated tests for mount-mode branches.

**Entrypoint process supervision:**
- Why fragile: dual long-lived processes with PID tracking and trap cleanup.
- Common failures: one process exits unexpectedly; diagnosing root cause requires log correlation.
- Safe modification: preserve liveness checks and error branch semantics during refactors.
- Test coverage: no regression test harness for PID/cleanup flow.

## Scaling Limits

**Single-container control-plane model:**
- Current capacity: one teamserver + one REST instance per container invocation.
- Limit: horizontal scaling and HA strategy are not defined in-repo.
- Symptoms at limit: maintenance windows and single-instance failure domains.
- Scaling path: external orchestration + persistent storage strategy documentation.

## Dependencies at Risk

**Upstream installer endpoint contract:**
- Risk: Docker build depends on HTML parsing from `download.cobaltstrike.com` token response.
- Impact: endpoint format changes can break build without code changes.
- Migration plan: move to a documented/stable distribution API if available.

**Action ecosystem drift:**
- Risk: GitHub Actions + Gemini integrations depend on external action behavior and token scopes.
- Impact: automation failures in triage/review pipelines.
- Migration plan: pin/monitor action versions and add workflow health checks.

## Missing Critical Features

**No automated regression tests for launcher/entrypoint scripts:**
- Problem: behavior changes can regress mount logic, env parsing, or startup sequencing unnoticed.
- Current workaround: manual `bash -n` and runtime smoke testing.
- Blocks: safe refactors and rapid iteration on operational logic.
- Implementation complexity: medium (shell test harness + CI wiring).

## Test Coverage Gaps

**Shell function behavior and edge-case validation:**
- What's not tested: `.env` parser edge cases, mount probe branches, timeout/error paths.
- Risk: subtle startup regressions and platform-specific breakage.
- Priority: High.
- Difficulty to test: Medium (requires deterministic shell fixtures and docker stubs).

---

*Concerns audit: 2026-02-25*
*Update as issues are fixed or new ones are discovered*
