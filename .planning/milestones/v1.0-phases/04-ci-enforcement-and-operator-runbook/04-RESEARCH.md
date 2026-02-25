# Phase 4: CI Enforcement and Operator Runbook - Research

**Researched:** 2026-02-25
**Domain:** Pull-request CI enforcement and operator troubleshooting documentation
**Confidence:** HIGH

## User Constraints

### Locked Decisions (from CONTEXT.md)
- Dedicated reliability workflow with `pull_request` trigger on `master` + `release/**`.
- Blocking CI jobs for syntax checks, shell regression suite, and secret scan.
- Read-only fork-safe checks with no secret dependencies.
- Dedicated runbook at `docs/TROUBLESHOOTING.md` with README pointer.
- Required troubleshooting sections: startup, mount fallback/profile source, health verification, CI failure triage.
- Command-first `Symptom -> Checks -> Fix commands` structure with top-level quick validation block.

### Claude's Discretion
- Exact workflow and job naming while preserving required check semantics.
- Exact wording/layout for troubleshooting procedures.
- Minor docs placement adjustments for readability.

### Deferred Ideas
- Branch protection automation.
- Additional static tooling rollout.
- Multi-OS CI matrix.

## Summary

The repository already has deterministic runtime checks and a local shell regression suite from Phases 1-3. Phase 4 should avoid introducing new dependencies and instead wire those existing checks into a dedicated pull-request workflow. Documentation currently spreads troubleshooting details across README sections; moving operational triage into a single runbook file with a short README pointer will satisfy DOC-02 while reducing future drift.

**Primary recommendation:** implement one dedicated `runtime-reliability` workflow with three blocking jobs and create a dedicated `docs/TROUBLESHOOTING.md` runbook that maps CI failures directly to local reproduction commands.

## Current Baseline Findings

### CI
- Existing `.github/workflows/*` are Gemini automation pipelines, not runtime reliability gates.
- No dedicated PR workflow currently enforces:
  - `bash -n` for both shell entrypoints,
  - `./tests/run-shell-tests.sh`,
  - `./scripts/scan-secrets.sh .`

### Runtime checks
- Shell regression suite exists and passes locally via `./tests/run-shell-tests.sh`.
- Secret-scan script exists and already targets planning/docs markdown artifacts.
- Syntax checks are stable and low-friction.

### Documentation
- README contains diagnostics and shell-test sections, but no dedicated troubleshooting runbook path.
- AGENTS lacks explicit runbook path guidance.

## Recommended Patterns

### Pattern 1: Dedicated reliability workflow
- Keep reliability gates separate from bot workflows.
- Prevent accidental drift from automation workflow changes.
- Make required status checks explicit.

### Pattern 2: Reproduce-in-place commands
- CI job commands must match runbook local commands verbatim where practical.
- Ensures contributors can debug CI failures quickly.

### Pattern 3: Troubleshooting by symptom
- Lead with symptoms and expected signals.
- Provide direct checks and fix commands.
- Keep sections bounded to Phase 4 required coverage.

## Risks and Mitigations

### Risk: Existing workflows still target `main` in some branches
- Mitigation: new reliability workflow explicitly targets `master` + `release/**` per current repo branch model.

### Risk: Secret scan false positives can block PRs
- Mitigation: keep scan scope and patterns aligned with current script behavior; document interpretation and remediation in runbook.

### Risk: Runbook drifts from CI commands
- Mitigation: include CI failure triage section mapping each workflow job to exact local reproduction command.

## Verification Strategy

1. Syntax checks:
   - `bash -n /opt/Cobalt-Docker/cobalt-docker.sh`
   - `bash -n /opt/Cobalt-Docker/docker-entrypoint.sh`
2. Shell regression:
   - `./tests/run-shell-tests.sh`
3. Secret scan:
   - `./scripts/scan-secrets.sh /opt/Cobalt-Docker`
4. Workflow lint-by-inspection:
   - Ensure pull request trigger branches and job commands match locked decisions.

## Sources

### Primary (HIGH confidence)
- `/opt/Cobalt-Docker/.planning/phases/04-ci-enforcement-and-operator-runbook/04-CONTEXT.md`
- `/opt/Cobalt-Docker/.planning/ROADMAP.md`
- `/opt/Cobalt-Docker/.planning/REQUIREMENTS.md`
- `/opt/Cobalt-Docker/README.md`
- `/opt/Cobalt-Docker/AGENTS.md`
- `/opt/Cobalt-Docker/.github/workflows/*.yml`
- `/opt/Cobalt-Docker/tests/run-shell-tests.sh`
- `/opt/Cobalt-Docker/scripts/scan-secrets.sh`

## Metadata
- Research mode: phase-specific
- User decisions honored: yes
- Deferred ideas excluded: yes
