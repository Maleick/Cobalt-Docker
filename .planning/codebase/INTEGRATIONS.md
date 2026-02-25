# External Integrations

**Analysis Date:** 2026-02-25

## APIs & External Services

**Cobalt Strike Distribution Service:**
- `download.cobaltstrike.com` - used in `Dockerfile` to fetch installer tarball token/artifacts
  - Integration method: HTTPS requests via `curl`
  - Auth: license key sent as `dlkey` build argument during image build
  - Dependency risk: build fails if endpoint changes or license is invalid

**Tailscale Control Plane:**
- Tailscale service - optional private-network connectivity for teamserver exposure
  - Integration method: `tailscaled` + `tailscale up` from `docker-entrypoint.sh`
  - Auth: `TS_AUTHKEY` and optional `TS_API_KEY` environment variables
  - Behavior: optional `USE_TAILSCALE_IP=true` rewrites teamserver bind host

**GitHub/Gemini Automation:**
- GitHub Actions + Google Gemini action integration under `.github/workflows/`
  - Integration method: reusable workflows and action calls
  - Auth: GitHub App token minting and GitHub-provided tokens/secrets
  - Scope: issue triage, pull request review, and request dispatch automation

## Data Storage

**Databases:**
- Teamserver experimental database mode (`--experimental-db`) managed by Cobalt Strike runtime
  - Configuration path: startup args in `docker-entrypoint.sh`
  - No repository-managed schema or migration framework

**File Storage:**
- Host bind mount to `/opt/cobaltstrike/mount` when daemon-visible
  - Source controlled by `MOUNT_SOURCE` / `COBALT_DOCKER_MOUNT_SOURCE`
  - Fallback mode uses in-image profiles only when bind mount is unavailable

**Caching:**
- No explicit caching layer in repository scripts

## Authentication & Identity

**REST API Authentication:**
- `csrestapi` uses `REST_API_USER` and `TEAMSERVER_PASSWORD`
- Credentials provided via `.env` and passed as container environment variables

**Network Identity:**
- Optional Tailscale node identity and Tailnet join through `TS_AUTHKEY`
- Optional dynamic teamserver host override via `tailscale ip -4`

## Monitoring & Observability

**Health Monitoring:**
- TLS probe: `openssl s_client` against teamserver upstream host/port
- HTTP probe: `curl` to `HEALTHCHECK_URL` with optional insecure TLS mode

**Logs:**
- Process-level logs via `docker logs cobaltstrike_server`
- No centralized observability stack defined in this repo

## CI/CD & Deployment

**Hosting/Runtime:**
- Self-hosted Docker target invoked by `./cobalt-docker.sh`

**CI Pipeline:**
- GitHub Actions workflows under `.github/workflows/`
  - `gemini-dispatch.yml`, `gemini-review.yml`, `gemini-triage.yml`, `gemini-scheduled-triage.yml`, `gemini-invoke.yml`
- GitHub secrets/vars drive authentication to GitHub App and Gemini providers

## Environment Configuration

**Development:**
- `.env` is required and gitignored (`.gitignore` includes `.env`)
- `.env.example` is expected as template per `README.md` and `AGENTS.md`

**Production:**
- Secrets are injected as environment variables at container start
- REST API host exposure defaults to localhost-only publish mapping on host

## Webhooks & Callbacks

**Incoming:**
- No webhook endpoints defined in repository scripts

**Outgoing:**
- No outbound webhook integrations implemented by launcher/entrypoint logic

---

*Integration audit: 2026-02-25*
*Update when adding/removing external services*
