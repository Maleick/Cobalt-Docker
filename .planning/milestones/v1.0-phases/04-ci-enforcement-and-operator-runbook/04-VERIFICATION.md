status: passed
score: 2/2

# Phase 4 Verification

## Goal
Enforce reliability checks continuously and ship a clear troubleshooting runbook.

## Requirement Checks
- TEST-04: passed
- DOC-02: passed

## Evidence
- Added dedicated PR workflow: `.github/workflows/runtime-reliability-gates.yml`.
- Workflow trigger scope matches locked decision:
  - `pull_request` only
  - base branches `master` and `release/**`
  - permissions: `contents: read`
  - concurrency cancellation enabled for same PR/ref.
- Blocking CI job surface implemented with exact command contract:
  - `runtime-reliability / syntax-checks` -> `bash -n cobalt-docker.sh` and `bash -n docker-entrypoint.sh`
  - `runtime-reliability / shell-regression-suite` -> `./tests/run-shell-tests.sh`
  - `runtime-reliability / secret-scan` -> `./scripts/scan-secrets.sh .`
- Added dedicated runbook: `docs/TROUBLESHOOTING.md` with required sections:
  - Quick Validation
  - Startup Troubleshooting
  - Mount Fallback Troubleshooting
  - Health Verification Troubleshooting
  - CI Failure Triage
- README and AGENTS now point to `docs/TROUBLESHOOTING.md` as canonical troubleshooting guidance.
- Verification checks passed:
  - `bash -n /opt/Cobalt-Docker/cobalt-docker.sh`
  - `bash -n /opt/Cobalt-Docker/docker-entrypoint.sh`
  - `./tests/run-shell-tests.sh` (passed: 2 spec files)
  - `./scripts/scan-secrets.sh /opt/Cobalt-Docker` (no potential secrets found)

## Outcome
Phase 4 requirements are satisfied: runtime reliability checks are enforced on target PRs and operator/contributor troubleshooting guidance is complete and reproducible.
