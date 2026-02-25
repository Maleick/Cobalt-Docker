# Requirements: Cobalt-Docker Branch Protection Governance

**Defined:** 2026-02-25
**Core Value:** A licensed operator can start the stack safely and predictably with one command, and failures are explicit, diagnosable, and recoverable.

## v1.1 Requirements

Requirements for milestone v1.1. Each requirement maps to exactly one roadmap phase.

### Governance Policy

- [x] **GOV-01**: Protected branch scope is explicitly defined for `master` and `release/**`.
- [x] **GOV-02**: Required status checks are explicitly pinned to:
  - `runtime-reliability / syntax-checks`
  - `runtime-reliability / shell-regression-suite`
  - `runtime-reliability / secret-scan`
- [x] **GOV-03**: PR review governance rules are documented, including approval threshold, stale review handling, and required conversation resolution.
- [x] **GOV-04**: Direct-push and force-push exception policy is defined with least-privilege scope.

### Verification & Audit

- [x] **AUD-01**: A reproducible verification procedure (CLI and UI path) is documented to confirm effective protection settings.
- [x] **AUD-02**: An emergency exception workflow is documented with post-incident reconciliation checklist and ownership.

## v1.2 Deferred Requirements

Deferred to the next milestone by explicit scope split.

### CI and Operations Expansion

- **REL-01**: Expand CI reliability depth (for example `shellcheck` policy and/or multi-OS matrix).
- **OPS-01**: Add post-start operational hardening docs beyond the current troubleshooting runbook scope.
- **EVD-01**: Improve contributor evidence-capture process for governance compliance and audit traceability.

## Out of Scope

Explicit exclusions for v1.1.

| Feature | Reason |
|---------|--------|
| Runtime behavior refactors | v1.1 is governance policy only |
| New runtime features unrelated to branch governance | Scope deferred to later milestones |
| Broad ops handbook expansion | Deferred to v1.2 (`OPS-01`) |

## Traceability

Which phases cover which requirements. Updated during roadmap creation.

| Requirement | Phase | Status |
|-------------|-------|--------|
| GOV-01 | Phase 5 | Complete |
| GOV-02 | Phase 5 | Complete |
| GOV-03 | Phase 5 | Complete |
| GOV-04 | Phase 6 | Complete |
| AUD-01 | Phase 6 | Complete |
| AUD-02 | Phase 6 | Complete |

**Coverage:**
- v1.1 requirements: 6 total
- Mapped to phases: 6
- Unmapped: 0 ✓

---
*Requirements defined: 2026-02-25*
*Last updated: 2026-02-25 after v1.1 roadmap mapping*
