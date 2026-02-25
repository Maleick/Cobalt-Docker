# Requirements: Cobalt-Docker Runtime Hardening

**Defined:** 2026-02-25
**Core Value:** A licensed operator can start the stack safely and predictably with one command, and failures are explicit, diagnosable, and recoverable.

## v1 Requirements

Requirements for the current hardening milestone. Each requirement maps to exactly one roadmap phase.

### Configuration & Preflight

- [ ] **CONF-01**: Operator can initialize `.env` from a maintained template that includes all required runtime keys.
- [ ] **CONF-02**: Launcher rejects missing/empty required keys (`COBALTSTRIKE_LICENSE`, `TEAMSERVER_PASSWORD`) with explicit remediation output.
- [ ] **CONF-03**: Launcher validates runtime port and boolean controls and exits with actionable error messages for invalid values.

### Startup & Health Contracts

- [ ] **STRT-01**: Entrypoint starts teamserver first and only starts `csrestapi` after teamserver TLS readiness succeeds.
- [ ] **STRT-02**: Entrypoint exits non-zero when teamserver or `csrestapi` exits unexpectedly during startup.
- [ ] **STRT-03**: Healthy startup can be verified using documented TLS and HTTP health commands.
- [ ] **STRT-04**: Startup logs expose clear phase markers and failure causes for fast operator diagnosis.

### Mount & Platform Resilience

- [ ] **MNT-01**: Launcher deterministically chooses bind mount or fallback mode using an explicit daemon-visibility probe.
- [ ] **MNT-02**: Selected profile source (bind-mounted vs in-image fallback) is clearly surfaced to operators.
- [ ] **MNT-03**: Host IP/runtime host selection handles platform variance without silent failure.

### Security & Exposure

- [ ] **SEC-01**: Scripts and generated docs avoid printing or storing secret values.
- [ ] **SEC-02**: REST API host publish remains localhost-scoped by default unless operator explicitly overrides.
- [ ] **SEC-03**: Planning/docs artifacts pass secret-pattern scans before commit.

### Testing & CI

- [ ] **TEST-01**: Automated shell tests cover preflight validation branches.
- [ ] **TEST-02**: Automated shell tests cover mount-mode decision branches.
- [ ] **TEST-03**: Automated shell tests cover startup sequencing and readiness branch behavior.
- [ ] **TEST-04**: CI executes syntax/static checks and shell regression tests on pull requests.

### Documentation Contract

- [ ] **DOC-01**: `README.md` and `AGENTS.md` stay aligned with launcher/entrypoint behavior changes.
- [ ] **DOC-02**: Troubleshooting guidance covers expected startup, mount fallback, and health verification flows.

## v2 Requirements

Deferred to future releases.

### Expansion

- **EXP-01**: Multi-environment deployment overlays for team-scale operations.
- **EXP-02**: Broader host/platform smoke matrix beyond baseline target environments.
- **EXP-03**: Advanced runtime observability integration (structured telemetry dashboards/alerts).

## Out of Scope

Explicit exclusions for this milestone.

| Feature | Reason |
|---------|--------|
| Unauthorized or malicious Cobalt Strike workflows | Violates project purpose and legal/ethical boundaries |
| Replacing Cobalt Strike core binaries/services | Not required for runtime hardening objectives |
| Full orchestration rewrite before baseline tests exist | High risk and unnecessary for current milestone goals |

## Traceability

Which phases cover which requirements. Updated during roadmap creation.

| Requirement | Phase | Status |
|-------------|-------|--------|
| CONF-01 | TBD | Pending |
| CONF-02 | TBD | Pending |
| CONF-03 | TBD | Pending |
| STRT-01 | TBD | Pending |
| STRT-02 | TBD | Pending |
| STRT-03 | TBD | Pending |
| STRT-04 | TBD | Pending |
| MNT-01 | TBD | Pending |
| MNT-02 | TBD | Pending |
| MNT-03 | TBD | Pending |
| SEC-01 | TBD | Pending |
| SEC-02 | TBD | Pending |
| SEC-03 | TBD | Pending |
| TEST-01 | TBD | Pending |
| TEST-02 | TBD | Pending |
| TEST-03 | TBD | Pending |
| TEST-04 | TBD | Pending |
| DOC-01 | TBD | Pending |
| DOC-02 | TBD | Pending |

**Coverage:**
- v1 requirements: 19 total
- Mapped to phases: 0
- Unmapped: 19 ⚠️

---
*Requirements defined: 2026-02-25*
*Last updated: 2026-02-25 after initial definition*
