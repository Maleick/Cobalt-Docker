# Pitfalls Research

**Domain:** Cobalt Strike Docker deployment hardening
**Researched:** 2026-02-25
**Confidence:** HIGH

## Critical Pitfalls

### Pitfall 1: Secrets leak through operational artifacts

**What goes wrong:**
Sensitive values end up in logs, commits, or copied command history.

**Why it happens:**
Teams prioritize speed and debug verbosity over secret hygiene.

**How to avoid:**
Use strict secret redaction rules, never print secret values, and gate docs/outputs through secret scans.

**Warning signs:**
Config examples include real-looking tokens, or troubleshooting output copies full env values.

**Phase to address:**
Phase 1 (security baseline and guardrails).

---

### Pitfall 2: Startup appears healthy while partially broken

**What goes wrong:**
One process is up but dependency sequencing is wrong, causing latent failures.

**Why it happens:**
Readiness checks are overly permissive or not tied to process liveness.

**How to avoid:**
Keep chained readiness gates with explicit liveness checks and bounded retries.

**Warning signs:**
Intermittent startup failures, early handshake noise, or service exits shortly after “healthy” logs.

**Phase to address:**
Phase 2 (startup and readiness contract hardening).

---

### Pitfall 3: Platform-specific assumptions break portability

**What goes wrong:**
Host networking or mount assumptions fail on different OS/docker contexts.

**Why it happens:**
Scripts are validated in one environment only.

**How to avoid:**
Codify platform checks, fallback modes, and matrix-style smoke validation.

**Warning signs:**
Frequent “works on my machine” behavior and user reports tied to host type.

**Phase to address:**
Phase 3 (test matrix and platform resilience).

---

### Pitfall 4: Documentation drifts from runtime behavior

**What goes wrong:**
Operators follow docs that no longer match script defaults or flags.

**Why it happens:**
Runtime and docs are changed in separate passes.

**How to avoid:**
Enforce docs+runtime update policy in each phase and add drift checks in CI.

**Warning signs:**
Repeated support questions about setup, mismatch between README steps and real flags.

**Phase to address:**
Phase 4 (contract alignment and maintainability).

## Technical Debt Patterns

| Shortcut | Immediate Benefit | Long-term Cost | When Acceptable |
|----------|-------------------|----------------|-----------------|
| Manual ad-hoc verification only | Fast initial shipping | Regressions slip through | Short-lived prototypes only |
| Hardcoded host-interface assumptions | Simpler scripts | Cross-platform failures | Never for general operator tooling |
| Broad default port publishing | Fewer setup steps | Larger attack surface | Never by default |

## Integration Gotchas

| Integration | Common Mistake | Correct Approach |
|-------------|----------------|------------------|
| Docker mount behavior | Assume host path is always daemon-visible | Probe capability first, then fallback with explicit logs |
| Tailscale runtime | Treat as always-on dependency | Keep optional and validate auth/path before use |
| Cobalt Strike download | Assume upstream response format is stable forever | Add failure messaging and maintain fallback guidance |

## Performance Traps

| Trap | Symptoms | Prevention | When It Breaks |
|------|----------|------------|----------------|
| Rebuilding image for every tiny change | Slow feedback loops | Cache strategy + staged validation | Frequent local iteration |
| Long opaque startup loops | Hard incident triage | Emit phase markers and reasoned timeout errors | Under intermittent runtime failures |
| Serial manual smoke checks | Missed regressions | Scripted smoke checks in CI | As contributor count grows |

## Security Mistakes

| Mistake | Risk | Prevention |
|---------|------|------------|
| Printing env values in debug logs | Credential exposure | Redact and avoid echoing secret fields |
| Defaulting to wide network exposure | Unintended access paths | Keep localhost defaults, require explicit override |
| Treating sample env files as optional to maintain | Onboarding misconfiguration | Keep `.env.example` synchronized and validated |

## UX Pitfalls

| Pitfall | User Impact | Better Approach |
|---------|-------------|-----------------|
| Ambiguous startup failure messages | Slow recovery and confusion | Provide precise failure reason + next command to run |
| Hidden fallback mode | Unexpected runtime behavior | Log selected mode and profile source clearly |
| Incomplete troubleshooting docs | Repeated support loops | Keep a concise, tested diagnostics checklist |

## "Looks Done But Isn't" Checklist

- [ ] **Preflight:** required keys validated for missing/empty and malformed values
- [ ] **Startup sequencing:** teamserver readiness gate enforced before REST start
- [ ] **Mount behavior:** both bind and fallback paths exercised in tests
- [ ] **Documentation:** README and AGENTS reflect current behavior and validation commands
- [ ] **Security posture:** secret-safe outputs and explicit exposure defaults verified

## Recovery Strategies

| Pitfall | Recovery Cost | Recovery Steps |
|---------|---------------|----------------|
| Secret leak in docs/logs | HIGH | Rotate secrets, purge history/logs where possible, add scanning gate |
| Startup instability | MEDIUM | Reproduce with deterministic probes, tighten readiness checks, add regression test |
| Platform-specific failure | MEDIUM | Isolate host assumption, add conditional logic and platform test case |
| Contract drift | LOW/MEDIUM | Update docs + scripts together and add drift verification |

## Pitfall-to-Phase Mapping

| Pitfall | Prevention Phase | Verification |
|---------|------------------|--------------|
| Secret leak risk | Phase 1 | No secret-pattern matches in docs/scripts output paths |
| Startup partial-health risk | Phase 2 | Automated tests confirm ordered readiness semantics |
| Platform assumption failures | Phase 3 | Matrix/smoke checks pass across target environments |
| Docs/runtime drift | Phase 4 | Contract checks and docs validation pass in CI |

## Sources

- `.planning/codebase/CONCERNS.md`
- `README.md`, `AGENTS.md`
- launcher and entrypoint implementation scripts

---
*Pitfalls research for: Cobalt Strike Docker deployment hardening*
*Researched: 2026-02-25*
