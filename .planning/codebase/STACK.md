# Technology Stack

**Analysis Date:** 2026-02-25

## Languages

**Primary:**
- Bash (POSIX shell scripting) - orchestration logic in `cobalt-docker.sh` and `docker-entrypoint.sh`
- Dockerfile syntax - container build definition in `Dockerfile`

**Secondary:**
- YAML - GitHub Actions workflow definitions in `.github/workflows/*.yml`
- TOML - Gemini command prompts in `.github/commands/*.toml`
- Markdown - operator and agent documentation in `README.md` and `AGENTS.md`

## Runtime

**Environment:**
- Docker runtime (image built from `ubuntu:latest`) for production execution
- Linux userspace inside container with OpenJDK 17 for Cobalt Strike components
- Host shell runtime for launcher script (`bash`, `docker`, `openssl`, `curl`)

**Package Manager:**
- Apt (`apt-get`) used in `Dockerfile` for system dependencies
- No application package manifest (`package.json`, `requirements.txt`, etc.) in this repo

## Frameworks

**Core:**
- Cobalt Strike Team Server (`teamserver`) started with `--experimental-db`
- Cobalt Strike REST API (`csrestapi`) launched after teamserver TLS readiness

**Testing/Validation:**
- Bash syntax checks via `bash -n`
- Runtime health probes via `openssl s_client` and `curl`

**Build/Dev:**
- Docker build pipeline driven by `cobalt-docker.sh`
- Optional profile linting via `c2lint` inside the built image

## Key Dependencies

**Critical:**
- Docker engine/CLI - image build, mount probing, and container lifecycle
- OpenSSL CLI - upstream TLS readiness checks (`tls_probe_endpoint`)
- curl - REST API health checks and Cobalt Strike download token retrieval
- tailscaled/tailscale - optional Tailnet connectivity within the container
- Java 17 runtime - required by Cobalt Strike server and REST components

**Infrastructure:**
- GitHub Actions - automation workflows under `.github/workflows/`
- GitHub/Gemini action integrations - issue triage/review/dispatch workflows

## Configuration

**Environment:**
- Required `.env` keys: `COBALTSTRIKE_LICENSE`, `TEAMSERVER_PASSWORD`
- Optional runtime controls include `REST_API_USER`, `SERVICE_PORT`, `UPSTREAM_PORT`, `HEALTHCHECK_*`, `TS_*`
- Host-side runtime overrides: `DOCKER_PLATFORM`, `MOUNT_SOURCE`, `COBALT_DOCKER_MOUNT_SOURCE`

**Build/Runtime Files:**
- `Dockerfile` - image definition and dependency installation
- `cobalt-docker.sh` - preflight, build, lint, mount mode, container run
- `docker-entrypoint.sh` - in-container process orchestration and readiness gates

## Platform Requirements

**Development:**
- macOS/Linux host with Docker available
- Network access to `download.cobaltstrike.com` and optional `tailscale.com`

**Production:**
- Docker-compatible host capable of exposing ports `50050`, `80`, `443`, `53/udp`
- Secure handling of license/password secrets via `.env` (gitignored)

---

*Stack analysis: 2026-02-25*
*Update after major runtime/dependency changes*
