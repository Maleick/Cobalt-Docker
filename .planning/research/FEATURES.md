# Feature Research

**Domain:** Cobalt Strike Docker deployment hardening
**Researched:** 2026-02-25
**Confidence:** HIGH

## Feature Landscape

### Table Stakes (Users Expect These)

Features users assume exist. Missing these = deployment feels unsafe or unusable.

| Feature | Why Expected | Complexity | Notes |
|---------|--------------|------------|-------|
| Required secret preflight | Prevents booting with invalid config | LOW | Already implemented for license/password keys |
| Ordered startup with readiness gates | Teamserver must be ready before REST API | MEDIUM | Existing entrypoint pattern is correct baseline |
| Deterministic mount behavior | Operators need profile loading to be predictable | MEDIUM | Bind-probe + fallback contract should remain explicit |
| Localhost REST publish default | Reduces accidental remote exposure | LOW | Keep secure-by-default host mapping |
| Actionable startup diagnostics | Operators need fast failure triage | MEDIUM | Structured logs and troubleshooting guidance are key |

### Differentiators (Competitive Advantage)

Features that set this repository apart from ad-hoc scripts.

| Feature | Value Proposition | Complexity | Notes |
|---------|-------------------|------------|-------|
| Automated shell regression test suite | Safer refactors with lower operational risk | MEDIUM | Highest leverage improvement for this project |
| Contract drift detection (docs vs runtime) | Prevents stale guidance and onboarding failures | MEDIUM | Can be added via CI checks and lint rules |
| Explicit fallback provenance logging | Makes profile source obvious during incidents | LOW | Improves operator trust and debugging speed |
| Scenario-driven smoke tests in CI | Confirms end-to-end startup health per change | HIGH | Requires controlled test fixtures and docker setup |

### Anti-Features (Commonly Requested, Often Problematic)

| Feature | Why Requested | Why Problematic | Alternative |
|---------|---------------|-----------------|-------------|
| “One script does everything automatically” without guardrails | Convenience | Increases blast radius and hidden side effects | Keep explicit modes/checkpoints and fail-fast validation |
| Broad default network exposure | Easier remote access | Unsafe defaults and accidental internet exposure | Explicit opt-in exposure plus documented firewall rules |
| Heavy orchestration rewrite too early | Feels modern | Adds complexity before test baseline exists | Stabilize current shell design first, then reconsider |

## Feature Dependencies

```text
Automated Regression Suite
    └──requires──> Deterministic Runtime Contracts
                       └──requires──> Clear Requirements + Traceability

Contract Drift Checks ──enhances──> Operator Documentation Reliability

Broad Network Exposure Defaults ──conflicts──> Secure-by-default posture
```

### Dependency Notes

- **Regression suite requires deterministic contracts:** tests are brittle if startup semantics are ambiguous.
- **Drift checks enhance docs reliability:** docs can be validated continuously against real runtime flags/defaults.
- **Broad default exposure conflicts with security posture:** should remain opt-in rather than default behavior.

## MVP Definition

### Launch With (v1)

- [ ] Automated checks for preflight, mount mode, startup sequencing, and health probes — essential reliability baseline
- [ ] Security guardrails for secret handling and network exposure defaults — essential safety baseline
- [ ] Contract-aligned docs with explicit verification commands — essential operator usability

### Add After Validation (v1.x)

- [ ] Expanded integration smoke matrix (Linux/macOS variants) — add after baseline tests stabilize
- [ ] Optional profile provenance and structured event logs — add once core checks are stable

### Future Consideration (v2+)

- [ ] Declarative multi-environment deployment overlays — defer until single-environment flow is stable
- [ ] Advanced runtime observability integrations — defer until immediate reliability gaps are closed

## Feature Prioritization Matrix

| Feature | User Value | Implementation Cost | Priority |
|---------|------------|---------------------|----------|
| Regression tests for shell contracts | HIGH | MEDIUM | P1 |
| Startup diagnostics hardening | HIGH | LOW | P1 |
| Security default tightening | HIGH | MEDIUM | P1 |
| Drift checks for docs/runtime | MEDIUM | MEDIUM | P2 |
| Expanded CI smoke matrix | MEDIUM | HIGH | P2 |
| Multi-environment orchestration expansion | LOW | HIGH | P3 |

**Priority key:**
- P1: Must have for launch
- P2: Should have, add when possible
- P3: Nice to have, future consideration

## Competitor Feature Analysis

| Feature | Competitor A | Competitor B | Our Approach |
|---------|--------------|--------------|--------------|
| Shell preflight hard-fail | Often partial/optional in community scripts | Frequently absent | Keep mandatory fail-fast preflight |
| Ordered runtime readiness gates | Sometimes sleep-based | Sometimes unmanaged | Maintain explicit TLS/HTTP readiness checks |
| Regression testing for shell orchestration | Rare in small repos | Rare | Treat as core differentiator for maintainability |

## Sources

- `.planning/codebase/*.md` map created for this repository
- `README.md` and `AGENTS.md` operational contracts
- existing runtime scripts: `cobalt-docker.sh`, `docker-entrypoint.sh`

---
*Feature research for: Cobalt Strike Docker deployment hardening*
*Researched: 2026-02-25*
