# AGENTS.md

This file documents how coding agents should work in this repository.

## Repo Purpose

This repository builds and runs a Cobalt Strike 4.12 Docker deployment with:

- strict `.env` preflight validation,
- automatic teamserver + REST API startup,
- Docker Desktop mount probe + fallback behavior.

## Canonical Entry Point

Use `./cobalt-docker.sh` as the primary workflow.

Do not hand-roll ad-hoc `docker run` invocations unless debugging a specific issue.

## Required Preflight Inputs

`.env` must exist and include:

- `COBALTSTRIKE_LICENSE`
- `TEAMSERVER_PASSWORD`

If either key is missing/empty, launcher exits by design.

Template file:

- `.env.example`

## REST API Integration Contract

The container entrypoint is `docker-entrypoint.sh` and it:

1. starts `teamserver --experimental-db`,
2. waits for teamserver TLS readiness,
3. starts `csrestapi`,
4. waits for HTTPS readiness before declaring startup healthy,
5. exits non-zero with phase-specific cause when startup/monitor branches fail.

Defaults:

- `UPSTREAM_HOST=127.0.0.1`
- `UPSTREAM_PORT=50050`
- `SERVICE_BIND_HOST=0.0.0.0`
- `SERVICE_PORT=50443`
- `REST_API_PUBLISH_BIND=127.0.0.1`
- host publish: `${REST_API_PUBLISH_BIND:-127.0.0.1}:${REST_API_PUBLISH_PORT:-50443}:${SERVICE_PORT}`

Deterministic startup log markers:

- `STARTUP[preflight]`
- `STARTUP[teamserver-launch]`
- `STARTUP[teamserver-ready]`
- `STARTUP[rest-launch]`
- `STARTUP[rest-ready]`
- `STARTUP[monitor]`

## Mount Fallback Contract

Launcher probes whether host `MOUNT_SOURCE` is daemon-visible for bind mounts.

- Probe success: use bind mount.
- Probe failure: fallback mode with in-image profiles only.
- Branch output must include explicit `Mount mode:` and `Profile source:` markers.

Fallback still expects selected profile to exist in `/opt/cobaltstrike/mount/<profile>`.

Host/runtime target selection:

- Auto-detect by platform defaults (Linux/macOS multi-strategy).
- Use `TEAMSERVER_HOST_OVERRIDE` when auto-detection is unreliable.

## Validation Commands

Run shell checks after script edits:

- `bash -n /opt/Cobalt-Docker/cobalt-docker.sh`
- `bash -n /opt/Cobalt-Docker/docker-entrypoint.sh`
- `./tests/run-shell-tests.sh`

## Secret Hygiene

Before committing docs/planning artifacts, run secret-pattern checks:

- `./scripts/scan-secrets.sh`

## Documentation Rule

When behavior changes, update `README.md` in the same change with:

- preflight requirements,
- auto-deploy behavior,
- optional flags/overrides,
- verification commands.
