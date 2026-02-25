# Stack Research

**Domain:** Cobalt Strike Docker deployment hardening
**Researched:** 2026-02-25
**Confidence:** MEDIUM

## Recommended Stack

### Core Technologies

| Technology | Version | Purpose | Why Recommended |
|------------|---------|---------|-----------------|
| Bash | 5.x+ | Host/runtime orchestration scripts | Existing repo already uses strict shell; minimal operational surface area |
| Docker Engine + CLI | 24.x+ | Build and run containerized teamserver stack | Native fit for current launcher design and operator workflows |
| Ubuntu base image | LTS stream | Stable runtime foundation for Cobalt Strike dependencies | Broad compatibility and package ecosystem |
| OpenSSL + curl | Current distro packages | TLS and HTTP readiness probing | Reliable health gates without custom binaries |
| GitHub Actions | Current | CI execution for lint/test automation | Existing `.github/workflows/` integration already present |

### Supporting Libraries

| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| bats-core | 1.x | Shell test harness | Regression tests for pure shell behavior and branch logic |
| shellcheck | 0.9+ | Static shell analysis | Catch quoting, globbing, and undefined-variable errors early |
| shfmt | 3.x | Shell formatting consistency | Keep scripts reviewable and reduce style churn |
| hadolint | 2.x | Dockerfile linting | Validate image hygiene and best practices before build regressions |

### Development Tools

| Tool | Purpose | Notes |
|------|---------|-------|
| GNU Make (optional) | Task aliases for lint/test/smoke | Helps standardize contributor commands |
| act (optional) | Local GitHub Actions dry runs | Useful for validating CI logic without pushing |
| jq | Structured JSON extraction in CI scripts | Already common in workflow contexts |

## Installation

```bash
# macOS (Homebrew)
brew install bash shellcheck shfmt bats-core hadolint jq

# Ubuntu/Debian (apt + package managers as needed)
sudo apt-get update
sudo apt-get install -y bash curl openssl jq shellcheck
# Install bats-core/shfmt/hadolint via preferred package source or release binaries
```

## Alternatives Considered

| Recommended | Alternative | When to Use Alternative |
|-------------|-------------|-------------------------|
| bats-core for shell tests | shunit2 | If organization already standardizes on shunit2 |
| single canonical launcher script | docker compose wrapper | If multi-service expansion requires declarative orchestration |
| `curl` + `openssl` probes | custom health binary | If richer telemetry and structured probe output are required |

## What NOT to Use

| Avoid | Why | Use Instead |
|-------|-----|-------------|
| `source .env` with untrusted shell syntax | Can execute unintended code paths | Parse keys explicitly as done in `get_env_value` |
| Unbounded sleep-based startup checks | Hides failure cause and adds nondeterminism | Bounded readiness loops with process-liveness checks |
| Public REST API publish defaults | Expands attack surface by default | Localhost publish + explicit operator opt-in for wider exposure |
| Unpinned third-party CI actions | Supply-chain drift and unexpected behavior changes | Pinned action SHAs and periodic controlled upgrades |

## Stack Patterns by Variant

**If local single-operator deployment:**
- Keep current script-first architecture.
- Add shell test coverage + CI lint gates.

**If multi-host/team deployment:**
- Introduce declarative environment overlays and stronger secret management integration.
- Add release tagging and reproducible build metadata.

## Version Compatibility

| Package A | Compatible With | Notes |
|-----------|-----------------|-------|
| Bash strict mode scripts | shellcheck + shfmt | Safe when scripts avoid bash-version-specific edge features |
| Docker runtime scripts | Ubuntu base + OpenJDK 17 | Matches existing Cobalt Strike runtime requirements |
| bats-core tests | GitHub Actions ubuntu runners | Stable default environment for shell test execution |

## Sources

- `README.md`, `AGENTS.md`, `cobalt-docker.sh`, `docker-entrypoint.sh` (repository contract and implementation)
- https://docs.docker.com/ (Docker engine/runtime guidance)
- https://www.shellcheck.net/ (shell static analysis)
- https://bats-core.readthedocs.io/ (shell testing framework)

---
*Stack research for: Cobalt Strike Docker deployment hardening*
*Researched: 2026-02-25*
