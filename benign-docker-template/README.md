# Benign Docker Template (Port 50051) with Optional Tailscale

This is a standalone, generic template for running a benign service in Docker with optional in-container Tailscale startup.

## What this template gives you

- Default service on `50051` with `/health` endpoint.
- Optional Tailscale startup, controlled by env vars.
- Explicit behavior when Tailscale config is missing:
  - `TS_REQUIRED=false`: warn and continue app startup.
  - `TS_REQUIRED=true`: fail fast.
- Platform pinning via `DOCKER_PLATFORM` on build/run commands, not in `FROM`.
- Docker Desktop bind-mount probe + fallback mode in `run.sh`.

## Files

- `Dockerfile`: generic app image + Tailscale binaries.
- `entrypoint.sh`: optional Tailscale init then app start.
- `run.sh`: build/run helper with mount probe fallback.
- `docker-compose.yml`: compose launch with optional kernel-mode comments.
- `.env.example`: required env shape.
- `tests/smoke_tailscale_modes.sh`: startup behavior smoke tests.
- `tests/assert_startup_stability.sh`: log + runtime stability assertion.

## Quick start

1. Prepare env:
```bash
cp .env.example .env
```

2. Start with helper:
```bash
./run.sh
```

3. Verify:
```bash
curl -fsS http://127.0.0.1:50051/health
```

## Tailscale envs

- `TS_ENABLE` (default `false`)
- `TS_REQUIRED` (default `false`)
- `TS_AUTHKEY` (required only for required mode)
- `TS_HOSTNAME` (default `app-node`)
- `TS_TUN_MODE` (`userspace` default; `kernel` optional)
- `TS_STATE_DIR` (default `/var/lib/tailscale`)
- `TS_SERVE_ENABLE` (default `false`)
- `TS_SERVE_TARGETS` (example: `tcp:50051->127.0.0.1:50051`)

## Startup examples

No Tailscale:
```bash
TS_ENABLE=false ./run.sh
```

Optional Tailscale (warn and continue if key missing):
```bash
TS_ENABLE=true TS_REQUIRED=false ./run.sh
```

Required Tailscale (fail if Tailscale init is incomplete):
```bash
TS_ENABLE=true TS_REQUIRED=true TS_AUTHKEY='tskey-...' ./run.sh
```

## Userspace vs kernel mode

- `userspace`:
  - No `/dev/net/tun` requirement.
  - Best default for portability.
- `kernel`:
  - Requires container privileges:
    - `cap_add: [NET_ADMIN, NET_RAW]`
    - `/dev/net/tun:/dev/net/tun`

## Docker Desktop shared-path troubleshooting

Symptom:
```text
invalid mount config for type "bind": bind source path does not exist
```

Cause:
- Docker daemon-visible paths may differ from shell-visible paths (common with Docker Desktop contexts).

Behavior in this template:
- `run.sh` probes mountability.
- If probe fails, it automatically runs in no-bind fallback mode.

Override example:
```bash
MOUNT_SOURCE=/Users/<user>/<project>/mount ./run.sh
```

## Compose

```bash
cp .env.example .env
docker compose up -d --build
```

If you set `TS_TUN_MODE=kernel`, uncomment the `cap_add` and `devices` section in `docker-compose.yml`.

## Smoke checks

Run behavior smoke tests:
```bash
./tests/smoke_tailscale_modes.sh
```

Assert startup stability for running container:
```bash
./tests/assert_startup_stability.sh benign_service
```
