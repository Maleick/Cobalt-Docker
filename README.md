# Cobalt Strike Docker

This project builds and runs a Cobalt Strike team server in Docker. It supports Cobalt Strike **4.12** and now starts the REST API (`csrestapi`) automatically alongside teamserver.

## Prerequisites

- [Docker](https://www.docker.com/get-started)
- A valid Cobalt Strike license key

## Required Preflight: Populate `.env` First

`cobalt-docker.sh` now requires a populated `.env` file before it will run.  
If `.env` is missing, or if required keys are empty, the script exits immediately and does not deploy.

### Required keys

- `COBALTSTRIKE_LICENSE`
- `TEAMSERVER_PASSWORD`

### Optional keys

- `REST_API_USER` (default: `csrestapi`)
- `REST_API_PUBLISH_PORT` (default: `50443`)
- `SERVICE_BIND_HOST` (default: `0.0.0.0`)
- `SERVICE_PORT` (default: `50443`)
- `UPSTREAM_HOST` (default: `127.0.0.1`)
- `UPSTREAM_PORT` (default: `50050`)
- `HEALTHCHECK_URL` (default: `https://127.0.0.1:${SERVICE_PORT}/health`)
- `HEALTHCHECK_INSECURE` (default: `true`)
- `TS_AUTHKEY` (Tailscale auth key for joining a Tailnet)
- `TS_API_KEY` (Tailscale API key for automation)
- `TS_EXTRA_ARGS` (Extra arguments for `tailscale up`)
- `TS_USERSPACE` (Set to `true` for macOS or environments without `/dev/net/tun`)
- `USE_TAILSCALE_IP` (Set to `true` to bind teamserver to the Tailscale IP)

### Runtime override environment variables (shell)

These are shell environment variables passed when invoking `cobalt-docker.sh` (not values stored in `.env`):

- `DOCKER_PLATFORM` (default: `linux/amd64`)
- `MOUNT_SOURCE` (generic bind-mount override; defaults to the repo directory)
- `COBALT_DOCKER_MOUNT_SOURCE` (legacy alias for `MOUNT_SOURCE`)

### Setup

```bash
cp .env.example .env
```

Edit `.env` and set real values for at least:

```dotenv
COBALTSTRIKE_LICENSE="your-license-key"
TEAMSERVER_PASSWORD="your-teamserver-password"
```

## Files

- `Dockerfile`: Builds the Cobalt Strike image and uses a custom entrypoint that starts both teamserver and REST API.
- `docker-entrypoint.sh`: Starts `teamserver --experimental-db`, waits for readiness, then starts `csrestapi`.
- `cobalt-docker.sh`: Validates `.env`, builds the image, optional profile linting, and runs the container.
- `AGENTS.md`: Local repository workflow guidance for coding agents.
- `.env.example`: Template for required and optional runtime configuration.
- `.gitignore`: Keeps secrets out of git (including `.env`) while allowing `.env.example`.
- `malleable.profile*` (Optional): If present, these profiles will be copied into the Docker image.

## Usage

1. Clone and enter the repository:

```bash
git clone https://github.com/Maleick/Cobalt-Docker.git
cd Cobalt-Docker
```

2. Populate `.env` as shown above.
3. Make the script executable:

```bash
chmod +x cobalt-docker.sh
```

4. Run:

```bash
./cobalt-docker.sh
```

### Custom profile

```bash
./cobalt-docker.sh custom.profile
```

### Profile linting (`c2lint`)

```bash
# Lint a specific profile only
./cobalt-docker.sh lint custom.profile

# Lint and then run
./cobalt-docker.sh custom.profile --lint
```

## REST API Integration

The REST API integration is built into the default deployment path.

If you run:

```bash
./cobalt-docker.sh
```

the launcher builds/runs the container and the entrypoint automatically starts both:

- `teamserver --experimental-db`
- `csrestapi`

No extra startup flag is required for standard REST API deployment.

### What is required

- `.env` must already contain:
  - `COBALTSTRIKE_LICENSE`
  - `TEAMSERVER_PASSWORD`

### Optional runtime controls

Use `.env` to override REST behavior when needed:

- `REST_API_USER` (default: `csrestapi`)
- `REST_API_PUBLISH_PORT` (default: `50443`)
- `SERVICE_BIND_HOST` (default: `0.0.0.0`)
- `SERVICE_PORT` (default: `50443`)
- `UPSTREAM_HOST` (default: `127.0.0.1`)
- `UPSTREAM_PORT` (default: `50050`)
- `HEALTHCHECK_URL` (default: `https://127.0.0.1:${SERVICE_PORT}/health`)
- `HEALTHCHECK_INSECURE` (default: `true`)

Example:

```dotenv
REST_API_USER="csrestapi"
REST_API_PUBLISH_PORT="50443"
SERVICE_BIND_HOST="0.0.0.0"
SERVICE_PORT="50443"
UPSTREAM_HOST="127.0.0.1"
UPSTREAM_PORT="50050"
HEALTHCHECK_URL="https://127.0.0.1:50443/health"
HEALTHCHECK_INSECURE="true"
```

### How to verify it is working

```bash
# service reachable (auth-protected endpoints may return 401/403)
curl -ksS -o /dev/null -w '%{http_code}\n' https://127.0.0.1:50443/health

# TLS negotiation works
openssl s_client -connect 127.0.0.1:50443 -servername localhost -brief </dev/null
```

## Tailscale Integration

This container includes [Tailscale](https://tailscale.com) for secure networking and remote access to the teamserver.

### Configuration

Add the following to your `.env` file to enable Tailscale:

```dotenv
# Required: join the Tailnet (ephemeral key recommended)
TS_AUTHKEY="tskey-auth-..."

# Optional: use Tailscale IP for the teamserver address
USE_TAILSCALE_IP="true"

# Optional: required for macOS or environments without TUN device access
TS_USERSPACE="true"

# Optional: extra arguments for 'tailscale up'
TS_EXTRA_ARGS="--hostname=cobalt-docker"
```

### Benefits

- **Secure Access**: Connect to your teamserver over a private Tailscale network without exposing ports to the public internet.
- **Stable IP**: Using `USE_TAILSCALE_IP="true"` ensures the teamserver binds to the stable Tailscale IP, simplifying beacon callback configuration.
- **Ephemeral Nodes**: Use ephemeral auth keys to ensure the container is automatically removed from your Tailnet when it stops.

## Runtime Behavior

On startup, the container entrypoint:

1. Starts `teamserver` with `--experimental-db`.
2. Waits for teamserver TLS readiness using `openssl s_client` (default upstream: `127.0.0.1:50050`).
3. Starts `csrestapi` using:
   - `--user $REST_API_USER`
   - `--pass $TEAMSERVER_PASSWORD`
   - `--host $UPSTREAM_HOST --port $UPSTREAM_PORT`
   - Spring bind env: `SERVER_ADDRESS=$SERVICE_BIND_HOST`, `SERVER_PORT=$SERVICE_PORT`
4. Waits for HTTPS readiness at `HEALTHCHECK_URL` (using `curl`, with `-k` when `HEALTHCHECK_INSECURE=true`), treating HTTP `2xx-4xx` as reachable.

If either process exits unexpectedly, the container exits.

## Network and Port Mapping

Host mappings configured by `cobalt-docker.sh`:

- `50050/tcp` (teamserver)
- `80/tcp`, `443/tcp` (HTTP/HTTPS listener ports)
- `53/udp` (DNS listener use cases)
- `127.0.0.1:${REST_API_PUBLISH_PORT}:${SERVICE_PORT}` (REST API, localhost-only by default)

By default, the REST API is reachable from the host at:

`https://127.0.0.1:50443`

## Docker Desktop Shared Paths and `/opt` Mount Failures

If you run Docker Desktop on macOS and see:

`invalid mount config for type "bind": bind source path does not exist`

the Docker daemon cannot see the host path even though your shell can. This commonly happens for paths outside Docker-shared roots (for example, `/opt/...`).

`cobalt-docker.sh` now probes mountability automatically:

- If mount probe succeeds: bind mount is used (`USE_BIND_MOUNT=true` behavior).
- If mount probe fails: script falls back to in-image profiles (`USE_BIND_MOUNT=false` behavior) and continues.

Fallback limitation:

- In fallback mode, only profiles baked into the image are available.
- Custom host profiles require a daemon-visible shared `MOUNT_SOURCE`.

Examples:

```bash
# Force a Docker-shared path for custom profiles
MOUNT_SOURCE=/Users/<user>/Cobalt-Docker ./cobalt-docker.sh

# Override platform at build/run time
DOCKER_PLATFORM=linux/amd64 ./cobalt-docker.sh
```

## TLS Handshake Warning Interpretation

`javax.net.ssl.SSLHandshakeException: Remote host terminated the handshake` can be startup noise (for example, a probe disconnecting early) or a real failure.  
Treat it as non-fatal only when all three checks pass:

1. HTTPS health endpoint succeeds.
2. TLS negotiation succeeds with `openssl`.
3. Process stays up after startup markers are logged.

### Generic diagnostics checklist

```bash
# 1) Inspect startup sequence
docker logs cobaltstrike_server

# 2) TLS-aware HTTP readiness check (self-signed certs)
curl -ksS -o /dev/null -w '%{http_code}\n' https://127.0.0.1:50443/health

# 3) Verify TLS negotiation directly
openssl s_client -connect 127.0.0.1:50443 -servername localhost -brief </dev/null

# 4) Confirm listener
lsof -iTCP:50443 -sTCP:LISTEN

# 5) Confirm env/port wiring
docker inspect cobaltstrike_server
```

## Failure Conditions

`cobalt-docker.sh` exits before build/run when:

- `.env` does not exist
- `COBALTSTRIKE_LICENSE` is missing/empty
- `TEAMSERVER_PASSWORD` is missing/empty
- `REST_API_PUBLISH_PORT` is invalid (not an integer from 1 to 65535)

## Notes for Cobalt Strike 4.12

- This repository has been validated with Cobalt Strike 4.12.
- The helper profiles `malleable.profile.4.12-drip` and `malleable.profile.4.12-drip-vaex` were linted with `c2lint`.
- If using a different Cobalt Strike version, re-lint your profiles and review Fortra release notes for behavior changes.

## Credits & Kudos

- **Cobalt Strike**: This project is based on Cobalt Strike by Fortra. A valid license is required.
- **Docker**: Thanks to the Docker community for container tooling and docs.
- **Inspiration**:
  - [White Knight Labs docker-cobaltstrike](https://github.com/WKL-Sec/docker-cobaltstrike)
  - [warhorse/docker-cobaltstrike](https://github.com/warhorse/docker-cobaltstrike)
  - [ZSECURE/zDocker-cobaltstrike](https://github.com/ZSECURE/zDocker-cobaltstrike/tree/main)
  - Blog post by Ezra Buckingham

## Disclaimer

This project is for authorized and ethical use only. The author is not responsible for misuse.
