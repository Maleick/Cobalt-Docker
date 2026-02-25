# Phase 1: Contract and Security Baseline - Research

**Researched:** 2026-02-25
**Domain:** Docker launcher contract hardening and secret-safe operational defaults
**Confidence:** HIGH

## User Constraints

### Locked Decisions (from CONTEXT.md)
- Required keys remain exactly `COBALTSTRIKE_LICENSE` and `TEAMSERVER_PASSWORD` and must hard-fail when missing/empty.
- Optional keys keep explicit defaults and invalid values fail early with actionable errors.
- `.env` bootstrap path must remain reproducible from a maintained template file.
- Script output/docs must never print raw secret values.
- Planning/docs artifacts should be scanned for secret-like patterns before commit.
- REST API publish mapping remains localhost-scoped by default; broader exposure must be explicit.
- Runtime behavior changes in this phase require same-phase `README.md` and `AGENTS.md` updates.

### Claude's Discretion
- Exact formatting/wording of validation and warning messages.
- Internal organization of checks across launcher/entrypoint.
- Documentation wording style while preserving contract semantics.

### Deferred Ideas
- Multi-environment deployment overlays and advanced observability integration.
- Broader platform matrix expansion beyond baseline checks.

## Summary

Phase 1 should strengthen existing contracts without introducing feature scope creep. The launcher already enforces required keys and validates critical ports/bools; the highest-value improvements are template integrity (`.env.example`), secret-safe operational behavior, and explicit contract alignment between runtime scripts and docs. The secure default exposure behavior is already present (localhost REST publish), so this phase should codify and test that contract rather than redesign networking.

**Primary recommendation:** Treat Phase 1 as contract codification plus guardrails, then hand off runtime sequencing and broader testing depth to subsequent phases.

## Standard Stack

### Core

| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| Bash strict mode | 5.x+ | Deterministic script behavior | Existing scripts already use `set -euo pipefail` |
| Docker CLI | 24.x+ | Build/run orchestration | Current deployment path is docker-native |
| `openssl` + `curl` | distro packages | Runtime readiness/health checks | Existing operational contract depends on these tools |

### Supporting

| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| shellcheck | 0.9+ | Static shell correctness checks | Validate contract changes to scripts |
| simple secret-pattern grep gate | n/a | Secret leak prevention on docs/planning files | Before commits containing docs/config examples |

### Alternatives Considered

| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| explicit `.env` parsing with awk | source `.env` directly | Faster to write but unsafe/untrusted parsing risks |
| localhost default publish | 0.0.0.0 default publish | More convenient but weaker default security posture |

## Architecture Patterns

### Recommended Project Structure

```text
runtime contracts:
- cobalt-docker.sh (host launcher contract)
- docker-entrypoint.sh (in-container startup contract)

documentation contracts:
- README.md
- AGENTS.md

template contract:
- .env.example
```

### Pattern 1: Fail-Fast Contract Validation
**What:** Validate required inputs and critical option formats before side effects.
**When to use:** Startup launchers and entrypoints handling secrets and runtime ports.

### Pattern 2: Secure-by-Default Exposure
**What:** Default to localhost-only API publish and require explicit operator override for broader scope.
**When to use:** Security-sensitive services with optional remote access.

### Anti-Patterns to Avoid
- Treating `.env.example` as optional documentation rather than an enforced onboarding contract.
- Adding debug output that echoes raw env values.
- Altering default exposure behavior silently without docs/contract updates.

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| `.env` parsing via shell eval | `source` on untrusted env file | Current `get_env_value` parser pattern | Prevents command execution risks |
| Ad-hoc secret checks spread across files | One-off manual inspections | Centralized regex-based pre-commit scan command | Repeatable and low-friction gate |
| Broad runtime policy rewrites in phase 1 | New networking subsystem | Keep existing publish contract and document explicit override path | Scope discipline and reduced regression risk |

## Common Pitfalls

### Pitfall 1: Config Template Drift
**What goes wrong:** Docs/scripts require `.env.example`, but file contents or presence drift.
**How to avoid:** Keep `.env.example` present and synchronized with required/optional keys.

### Pitfall 2: Secret Echo in Error Paths
**What goes wrong:** Helpful debug output accidentally includes sensitive values.
**How to avoid:** Never print secret values; show key names and remediation only.

### Pitfall 3: Ambiguous Security Defaults
**What goes wrong:** Operators misunderstand whether API is locally or broadly exposed.
**How to avoid:** Explicitly log publish binding behavior and keep docs consistent.

## Code Examples

### Secret-safe required key check

```bash
if [ -z "$TEAMSERVER_PASSWORD" ]; then
  echo "Error: TEAMSERVER_PASSWORD is missing or empty in $CONFIG_FILE"
  exit 1
fi
```

### Explicit localhost publish contract

```bash
-p "127.0.0.1:$REST_API_PUBLISH_PORT:$SERVICE_PORT"
```

## Open Questions

1. **Should Phase 1 introduce shellcheck in CI or only as local guidance?**
   - What we know: static checks are valuable and low-risk.
   - Recommendation: introduce as optional local check now, formal CI enforcement in Phase 4.

2. **How strict should secret-pattern scanning be for false positives?**
   - What we know: broad patterns catch leaks but can over-flag.
   - Recommendation: keep broad default regex and allow explicit human review on hits.

## Sources

### Primary (HIGH confidence)
- `/opt/Cobalt-Docker/cobalt-docker.sh`
- `/opt/Cobalt-Docker/docker-entrypoint.sh`
- `/opt/Cobalt-Docker/README.md`
- `/opt/Cobalt-Docker/AGENTS.md`
- `/opt/Cobalt-Docker/.planning/phases/01-contract-and-security-baseline/01-CONTEXT.md`

### Secondary (MEDIUM confidence)
- Shell tooling docs (shellcheck) and operational shell best practices

## Metadata
- Research mode: phase-specific
- User decisions honored: yes
- Deferred ideas excluded: yes
