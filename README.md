# Cobalt Strike Docker

Containerized Cobalt Strike 4.12 team server with automatic REST API startup.

![GitHub stars](https://img.shields.io/github/stars/Maleick/Cobalt-Docker?style=flat-square) ![License](https://img.shields.io/github/license/Maleick/Cobalt-Docker?style=flat-square) ![GitHub release](https://img.shields.io/github/v/release/Maleick/Cobalt-Docker?style=flat-square) ![Docker ready](https://img.shields.io/badge/docker-ready-blue?style=flat-square&logo=docker) ![Cobalt Strike 4.12](https://img.shields.io/badge/Cobalt%20Strike-4.12-red?style=flat-square) ![REST API](https://img.shields.io/badge/REST%20API-integrated-green?style=flat-square) ![CI](https://img.shields.io/github/actions/workflow/status/Maleick/Cobalt-Docker/runtime-reliability-gates.yml?style=flat-square&label=CI)

## Quick Start

```bash
git clone https://github.com/Maleick/Cobalt-Docker.git && cd Cobalt-Docker
cp .env.example .env
# Edit .env — set COBALTSTRIKE_LICENSE and TEAMSERVER_PASSWORD
./cobalt-docker.sh
```

## What This Does

- **Builds and runs** a Cobalt Strike 4.12 team server inside a Docker container with a single command.
- **Starts the REST API automatically** — `csrestapi` launches alongside teamserver with no extra flags.
- **Validates everything before launch** — `.env` preflight checks catch misconfiguration before Docker build/run.
- **Works on macOS and Linux** — automatic host detection, mount fallback for Docker Desktop, and Apple Silicon compatibility via `SKIP_REST_API`.

## Configuration

### Required

| Key                    | Default | Description                             |
| ---------------------- | ------- | --------------------------------------- |
| `COBALTSTRIKE_LICENSE` | —       | Your Cobalt Strike license key          |
| `TEAMSERVER_PASSWORD`  | —       | Password for team server authentication |

### Optional — REST API

| Key                     | Default                                    | Description                                                                |
| ----------------------- | ------------------------------------------ | -------------------------------------------------------------------------- |
| `REST_API_USER`         | `csrestapi`                                | REST API authentication username                                           |
| `REST_API_PUBLISH_PORT` | `50443`                                    | Host port for REST API                                                     |
| `REST_API_PUBLISH_BIND` | `127.0.0.1`                                | Host bind address for REST API (localhost-only by default)                 |
| `SERVICE_BIND_HOST`     | `0.0.0.0`                                  | In-container bind address for csrestapi                                    |
| `SERVICE_PORT`          | `50443`                                    | In-container port for csrestapi                                            |
| `UPSTREAM_HOST`         | `127.0.0.1`                                | Teamserver host that csrestapi connects to                                 |
| `UPSTREAM_PORT`         | `50050`                                    | Teamserver port that csrestapi connects to                                 |
| `HEALTHCHECK_URL`       | `https://127.0.0.1:${SERVICE_PORT}/health` | REST API health endpoint                                                   |
| `HEALTHCHECK_INSECURE`  | `true`                                     | Allow self-signed TLS for health checks                                    |
| `SKIP_REST_API`         | `false`                                    | Skip csrestapi startup (required for Apple Silicon — csrestapi needs AVX2) |

### Optional — Networking

| Key                         | Default   | Description                                                                                                |
| --------------------------- | --------- | ---------------------------------------------------------------------------------------------------------- |
| `COBALT_LISTENER_BIND_HOST` | `0.0.0.0` | Host bind address for C2 listener ports (80/443/53). Set to `127.0.0.1` if other services hold those ports |
| `TEAMSERVER_HOST_OVERRIDE`  | —         | Override auto-detected host IP passed to teamserver                                                        |

### Optional — Tailscale

| Key                | Default | Description                                                             |
| ------------------ | ------- | ----------------------------------------------------------------------- |
| `TS_AUTHKEY`       | —       | Tailscale auth key for joining a Tailnet (ephemeral recommended)        |
| `TS_API_KEY`       | —       | Tailscale API key for automation                                        |
| `TS_EXTRA_ARGS`    | —       | Extra arguments for `tailscale up` (e.g., `--hostname=cobalt-docker`)   |
| `TS_USERSPACE`     | `false` | Use userspace networking (required on macOS / environments without TUN) |
| `USE_TAILSCALE_IP` | `false` | Override teamserver host with the Tailscale IPv4 address                |

### Runtime Override Environment Variables

These are shell variables passed when invoking `cobalt-docker.sh`, not stored in `.env`:

| Variable                     | Default        | Description                                                           |
| ---------------------------- | -------------- | --------------------------------------------------------------------- |
| `DOCKER_PLATFORM`            | `linux/amd64`  | Docker `--platform` flag                                              |
| `MOUNT_SOURCE`               | repo directory | Bind-mount source override (use when Docker cannot see the repo path) |
| `COBALT_DOCKER_MOUNT_SOURCE` | —              | Legacy alias for `MOUNT_SOURCE`                                       |

## Usage Patterns

### Custom profile

```bash
./cobalt-docker.sh custom.profile
```

### Profile linting (c2lint)

```bash
# Lint only (no deploy)
./cobalt-docker.sh lint custom.profile

# Lint then deploy
./cobalt-docker.sh custom.profile --lint
```

### DyeDNV Wizard

Generate a `dyednv.v1` deployment spec interactively:

```bash
./scripts/dyednv-wizard.sh
```

Output lands in `configs/dyednv/<name>.dyednv.json`. The wizard pulls defaults from `.env` (or `.env.example`), validates all inputs, and stores only secret references — never raw secrets. See [docs/DYEDNV.md](./docs/DYEDNV.md) for the full spec format.

## REST API

The REST API starts automatically. No extra flags needed — the entrypoint launches `csrestapi` after confirming teamserver TLS readiness.

**Verify it is working:**

```bash
PORT="${REST_API_PUBLISH_PORT:-50443}"

# HTTP readiness (auth endpoints may return 401/403)
curl -ksS -o /dev/null -w '%{http_code}\n' "https://127.0.0.1:${PORT}/health"

# TLS negotiation
openssl s_client -connect "127.0.0.1:${PORT}" -servername localhost -brief </dev/null
```

**Apple Silicon:** csrestapi requires AVX2 instructions not available under Rosetta emulation. Set `SKIP_REST_API=true` in `.env` to run teamserver without the REST API.

**MCP integration:** You can build MCP tooling on top of the REST API, but MCP is not part of this project's default runtime.

## Tailscale Integration

Tailscale provides secure access to the team server over a private Tailnet without exposing ports publicly.

```dotenv
TS_AUTHKEY="tskey-auth-..."
USE_TAILSCALE_IP="true"
TS_USERSPACE="true"           # required on macOS / no TUN
TS_EXTRA_ARGS="--hostname=cobalt-docker"
```

- **Stable IP** — `USE_TAILSCALE_IP=true` binds teamserver to the Tailscale IPv4 address.
- **Ephemeral nodes** — use ephemeral auth keys so containers auto-remove from the Tailnet on stop.
- **Local-only mode** — leave `TS_AUTHKEY` empty to skip Tailscale entirely. An invalid key halts startup during Tailscale authentication.

## Runtime Behavior

### Startup Sequence

The entrypoint logs deterministic phase markers for triage:

| Marker                       | What happens                                                       |
| ---------------------------- | ------------------------------------------------------------------ |
| `STARTUP[preflight]`         | Validates inputs, binaries, port ranges, boolean flags             |
| `STARTUP[tailscale]`         | Starts tailscaled, authenticates (only when `TS_AUTHKEY` is set)   |
| `STARTUP[teamserver-launch]` | Starts teamserver with `--experimental-db`                         |
| `STARTUP[teamserver-ready]`  | TLS readiness confirmed via `openssl s_client` probe (60s timeout) |
| `STARTUP[rest-launch]`       | Starts csrestapi (skipped when `SKIP_REST_API=true`)               |
| `STARTUP[rest-ready]`        | HTTPS health check passes (HTTP 2xx-4xx = reachable)               |
| `STARTUP[monitor]`           | Both processes supervised; container exits if either dies          |

### Port Mapping

| Port                       | Protocol | Purpose                                                                |
| -------------------------- | -------- | ---------------------------------------------------------------------- |
| `50050`                    | TCP      | Teamserver                                                             |
| `80`                       | TCP      | HTTP listener (bound to `COBALT_LISTENER_BIND_HOST`)                   |
| `443`                      | TCP      | HTTPS listener (bound to `COBALT_LISTENER_BIND_HOST`)                  |
| `53`                       | UDP      | DNS listener (bound to `COBALT_LISTENER_BIND_HOST`)                    |
| `${REST_API_PUBLISH_PORT}` | TCP      | REST API (bound to `REST_API_PUBLISH_BIND`, localhost-only by default) |

Override the REST API bind to expose it beyond localhost:

```bash
REST_API_PUBLISH_BIND=0.0.0.0 ./cobalt-docker.sh
```

## Troubleshooting

**Quick diagnostics:**

```bash
PORT="${REST_API_PUBLISH_PORT:-50443}"

docker logs cobaltstrike_server                                           # 1. Check startup phases
curl -ksS -o /dev/null -w '%{http_code}\n' "https://127.0.0.1:${PORT}/health"  # 2. HTTP readiness
openssl s_client -connect "127.0.0.1:${PORT}" -servername localhost -brief </dev/null  # 3. TLS check
lsof -iTCP:"${PORT}" -sTCP:LISTEN                                        # 4. Confirm listener
docker inspect cobaltstrike_server                                        # 5. Verify env/port wiring
```

**TLS handshake warnings:** `SSLHandshakeException: Remote host terminated the handshake` is non-fatal startup noise if the health endpoint responds, TLS negotiation succeeds, and processes remain up after all `STARTUP[]` markers log.

**Preflight failures** — `cobalt-docker.sh` exits before build/run when:

- `.env` is missing or required keys are empty
- Port values are not integers in 1-65535
- Boolean settings are not `true` or `false`
- `TEAMSERVER_HOST_OVERRIDE` contains whitespace
- Host target auto-detection fails without an override set

Full runbook: [docs/TROUBLESHOOTING.md](./docs/TROUBLESHOOTING.md)

## Tested Environment

This project is developed and tested on **macOS (Apple Silicon)** using **[OrbStack](https://orbstack.dev/)** as the Docker runtime. OrbStack provides better x86 emulation compatibility than Docker Desktop for containers that require AVX2 instructions (like `csrestapi`).

**OrbStack setup notes:**

- **Rosetta mode** (default) — teamserver runs fine, but `csrestapi` may fail with an AVX2 CPU feature error. If this happens, disable "Use Rosetta to run Intel code" in OrbStack → System → Compatibility and restart.
- **QEMU mode** (Rosetta disabled) — full AVX2 support. Both teamserver and csrestapi run correctly. Slower than Rosetta but fully compatible.

The project also works with **Docker Desktop** on macOS and Linux. On native x86 hardware, no emulation settings are needed.

### Docker Desktop Mount Notes

On macOS, Docker Desktop may reject bind mounts for paths outside its shared directories (e.g., `/opt`).

`cobalt-docker.sh` handles this automatically:

- **Mount probe succeeds** — bind mount is used.
- **Mount probe fails** — falls back to in-image profiles and continues.

Launcher output shows the decision: `Mount mode: bind|fallback|none` and `Profile source: ...`

In fallback mode, only profiles baked into the image at build time are available. To use host profiles, set `MOUNT_SOURCE` to a Docker-shared path:

```bash
MOUNT_SOURCE=/Users/<you>/Cobalt-Docker ./cobalt-docker.sh
```

## Testing

Run the shell regression suite:

```bash
./tests/run-shell-tests.sh
```

Covers preflight validation, mount mode/profile source branching, and startup sequencing.

## Credits & Inspiration

- **[Cobalt Strike](https://www.cobaltstrike.com/)** by Fortra — a valid license is required.
- **Docker** community for container tooling and documentation.
- [White Knight Labs docker-cobaltstrike](https://github.com/WKL-Sec/docker-cobaltstrike)
- [warhorse/docker-cobaltstrike](https://github.com/warhorse/docker-cobaltstrike)
- [ZSECURE/zDocker-cobaltstrike](https://github.com/ZSECURE/zDocker-cobaltstrike)
- Blog post by Ezra Buckingham

## Disclaimer

This project is for authorized and ethical use only. The author is not responsible for misuse.
