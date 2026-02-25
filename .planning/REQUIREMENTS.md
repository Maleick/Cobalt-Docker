# Requirements: Cobalt-Docker Runtime Hardening

**Defined:** 2026-02-25
**Core Value:** A licensed operator can start the stack safely and predictably with one command, and failures are explicit, diagnosable, and recoverable.

## v1 Requirements

Requirements for the current hardening milestone. Each requirement maps to exactly one roadmap phase.

### Configuration & Preflight

- [x] **CONF-01**: Operator can initialize `.env` from a maintained template that includes all required runtime keys.
- [x] **CONF-02**: Launcher rejects missing/empty required keys (`COBALTSTRIKE_LICENSE`, `TEAMSERVER_PASSWORD`) with explicit remediation output.
- [x] **CONF-03**: Launcher validates runtime port and boolean controls and exits with actionable error messages for invalid values.

### Startup & Health Contracts

- [x] **STRT-01**: Entrypoint starts teamserver first and only starts `csrestapi` after teamserver TLS readiness succeeds.
- [x] **STRT-02**: Entrypoint exits non-zero when teamserver or `csrestapi` exits unexpectedly during startup.
- [x] **STRT-03**: Healthy startup can be verified using documented TLS and HTTP health commands.
- [x] **STRT-04**: Startup logs expose clear phase markers and failure causes for fast operator diagnosis.

### Mount & Platform Resilience

- [ ] **MNT-01**: Launcher deterministically chooses bind mount or fallback mode using an explicit daemon-visibility probe.
- [ ] **MNT-02**: Selected profile source (bind-mounted vs in-image fallback) is clearly surfaced to operators.
- [ ] **MNT-03**: Host IP/runtime host selection handles platform variance without silent failure.

### Security & Exposure

- [x] **SEC-01**: Scripts and generated docs avoid printing or storing secret values.
- [x] **SEC-02**: REST API host publish remains localhost-scoped by default unless operator explicitly overrides.
- [x] **SEC-03**: Planning/docs artifacts pass secret-pattern scans before commit.

### Testing & CI

- [ ] **TEST-01**: Automated shell tests cover preflight validation branches.
- [ ] **TEST-02**: Automated shell tests cover mount-mode decision branches.
- [ ] **TEST-03**: Automated shell tests cover startup sequencing and readiness branch behavior.
- [ ] **TEST-04**: CI executes syntax/static checks and shell regression tests on pull requests.

### Documentation Contract

- [x] **DOC-01**: `README.md` and `AGENTS.md` stay aligned with launcher/entrypoint behavior changes.
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

Which phases cover which requirements.

| Requirement | Phase | Status |
|-------------|-------|--------|
| CONF-01 | Phase 1 | Complete |
| CONF-02 | Phase 1 | Complete |
| SEC-01 | Phase 1 | Complete |
| SEC-02 | Phase 1 | Complete |
| SEC-03 | Phase 1 | Complete |
| DOC-01 | Phase 1 | Complete |
| CONF-03 | Phase 2 | Complete |
| STRT-01 | Phase 2 | Complete |
| STRT-02 | Phase 2 | Complete |
| STRT-03 | Phase 2 | Complete |
| STRT-04 | Phase 2 | Complete |
| MNT-01 | Phase 3 | Pending |
| MNT-02 | Phase 3 | Pending |
| MNT-03 | Phase 3 | Pending |
| TEST-01 | Phase 3 | Pending |
| TEST-02 | Phase 3 | Pending |
| TEST-03 | Phase 3 | Pending |
| TEST-04 | Phase 4 | Pending |
| DOC-02 | Phase 4 | Pending |

**Coverage:**
- v1 requirements: 19 total
- Mapped to phases: 19
- Unmapped: 0 ✓

---
*Requirements defined: 2026-02-25*
*Last updated: 2026-02-25 after phase 2 completion*
