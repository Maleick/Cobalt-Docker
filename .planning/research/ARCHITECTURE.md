# Architecture Research

**Domain:** Cobalt Strike Docker deployment hardening
**Researched:** 2026-02-25
**Confidence:** HIGH

## Standard Architecture

### System Overview

```text
┌─────────────────────────────────────────────────────────────┐
│                    Host Orchestration Layer                 │
├─────────────────────────────────────────────────────────────┤
│  ┌──────────────────────┐   ┌────────────────────────────┐  │
│  │ cobalt-docker.sh     │   │ .env + profile inputs      │  │
│  └──────────┬───────────┘   └──────────────┬─────────────┘  │
│             │                              │                │
├─────────────┴──────────────────────────────┴────────────────┤
│                   Container Bootstrap Layer                 │
├─────────────────────────────────────────────────────────────┤
│  ┌───────────────────────────────────────────────────────┐  │
│  │ docker-entrypoint.sh                                  │  │
│  │ teamserver -> TLS ready -> csrestapi -> HTTPS ready   │  │
│  └───────────────────────────────────────────────────────┘  │
├─────────────────────────────────────────────────────────────┤
│                    Service Runtime Layer                    │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────────┐  │
│  │ teamserver   │  │ csrestapi    │  │ optional tailscale│  │
│  └──────────────┘  └──────────────┘  └──────────────────┘  │
└─────────────────────────────────────────────────────────────┘
```

### Component Responsibilities

| Component | Responsibility | Typical Implementation |
|-----------|----------------|------------------------|
| Host launcher | Validate config, build image, run container | Strict Bash script with explicit guards |
| Entrypoint supervisor | Sequence process startup and cleanup | PID-aware shell with readiness probes |
| Runtime services | Serve control and API interfaces | Cobalt Strike binaries + Java runtime |
| CI workflows | Validate and automate repo behavior | GitHub Actions + pinned actions |

## Recommended Project Structure

```text
repo/
├── runtime/
│   ├── cobalt-docker.sh
│   └── docker-entrypoint.sh
├── docs/
│   ├── README.md
│   └── AGENTS.md
├── .planning/
│   ├── codebase/
│   ├── research/
│   ├── REQUIREMENTS.md
│   ├── ROADMAP.md
│   └── STATE.md
└── .github/
    ├── workflows/
    └── commands/
```

### Structure Rationale

- **runtime/** style boundary (conceptual): keeps startup contracts explicit and test-focused.
- **docs/** alignment: operator contract and implementation should evolve together.
- **.planning/** as execution memory: preserves requirements-to-phase traceability.

## Architectural Patterns

### Pattern 1: Fail-fast Contract Validation

**What:** Validate all critical inputs before build/run side effects.
**When to use:** Entry scripts with external dependencies and secrets.
**Trade-offs:** More upfront checks, but faster and safer failure feedback.

### Pattern 2: Readiness-Gated Process Chaining

**What:** Start dependent process only after upstream endpoint is verifiably ready.
**When to use:** Multi-process containers with startup ordering constraints.
**Trade-offs:** Slight startup delay versus dramatically better determinism.

### Pattern 3: Capability Probe + Fallback

**What:** Detect environment capabilities (bind mount visibility) and switch to safe fallback path.
**When to use:** Host/daemon behavior differs by platform.
**Trade-offs:** Additional branching complexity, improved portability.

## Data Flow

### Request Flow

```text
Operator command
  -> launcher validation/build/run
  -> container entrypoint
  -> teamserver readiness
  -> REST API readiness
  -> operator health checks and usage
```

### Key Data Flows

1. **Configuration flow:** `.env` + shell overrides -> launcher normalization -> container env vars.
2. **Startup flow:** teamserver process state -> TLS probe success -> REST API startup -> HTTP health success.
3. **Profile flow:** host mount probe -> bind mode or fallback profile path -> runtime startup arguments.

## Scaling Considerations

| Scale | Architecture Adjustments |
|-------|--------------------------|
| Single operator / single host | Current monolithic launcher + entrypoint is appropriate |
| Team operations across environments | Add environment overlays, better secrets controls, and CI smoke matrix |
| High change frequency contributors | Prioritize regression tests and contract checks before structural rewrites |

### Scaling Priorities

1. **First bottleneck:** confidence in script refactors without tests.
2. **Second bottleneck:** environment variance (host networking/mount behavior).

## Anti-Patterns

### Anti-Pattern 1: Implicit Startup Order

**What people do:** start all processes concurrently and hope dependencies settle.
**Why it's wrong:** creates nondeterministic failures and poor incident diagnosis.
**Do this instead:** enforce explicit readiness gates with bounded retries.

### Anti-Pattern 2: Docs Decoupled from Runtime

**What people do:** update scripts without updating operator docs.
**Why it's wrong:** onboarding and incident response degrade quickly.
**Do this instead:** treat docs as contract artifacts in same phase/commit scope.

## Integration Points

### External Services

| Service | Integration Pattern | Notes |
|---------|---------------------|-------|
| Cobalt Strike download endpoint | Build-time artifact retrieval via `curl` | Sensitive to upstream format/API changes |
| Tailscale control plane | Optional runtime auth + overlay networking | Must remain optional and explicit |
| GitHub Actions | Event-driven CI and automation workflows | Keep pinning and permission scopes tight |

### Internal Boundaries

| Boundary | Communication | Notes |
|----------|---------------|-------|
| Launcher -> Entrypoint | CLI args + env vars | Must preserve parameter contract stability |
| Entrypoint -> Services | Process invocation + health probes | Keep probes and timeouts explicit |
| Planning -> Execution | Requirements/roadmap/state artifacts | Enables consistent phase execution |

## Sources

- `.planning/codebase/ARCHITECTURE.md`, `.planning/codebase/STRUCTURE.md`
- `cobalt-docker.sh`, `docker-entrypoint.sh`, `Dockerfile`
- `README.md`, `AGENTS.md`

---
*Architecture research for: Cobalt Strike Docker deployment hardening*
*Researched: 2026-02-25*
