# Troubleshooting Runbook

Use this runbook when startup, mount selection, health checks, or CI reliability gates fail.

## Quick Validation

Run these commands first:

```bash
bash -n /opt/Cobalt-Docker/cobalt-docker.sh
bash -n /opt/Cobalt-Docker/docker-entrypoint.sh
./tests/run-shell-tests.sh
./scripts/scan-secrets.sh .
```

If any command fails, use the sections below to isolate and correct the failure.

## Startup Troubleshooting

### Symptom

- Container exits shortly after launch.
- `STARTUP[...] ERROR` appears in container logs.
- Teamserver or REST API never reaches ready state.

### Checks

```bash
docker logs cobaltstrike_server
```

Look for marker order:

1. `STARTUP[preflight]`
2. `STARTUP[teamserver-launch]`
3. `STARTUP[teamserver-ready]`
4. `STARTUP[rest-launch]`
5. `STARTUP[rest-ready]`
6. `STARTUP[monitor]`

Verify local startup controls:

```bash
grep -E '^(UPSTREAM_HOST|UPSTREAM_PORT|SERVICE_PORT|HEALTHCHECK_URL|HEALTHCHECK_INSECURE)=' .env
```

### Fix Commands

- Invalid ports or booleans in `.env`:

```bash
# example corrections
sed -i.bak 's/^HEALTHCHECK_INSECURE=.*/HEALTHCHECK_INSECURE="true"/' .env
sed -i.bak 's/^SERVICE_PORT=.*/SERVICE_PORT="50443"/' .env
```

- Retry startup:

```bash
./cobalt-docker.sh
```

## Mount Fallback Troubleshooting

### Symptom

- Profile not found during launch.
- Launcher reports fallback mode unexpectedly.
- Custom profile changes do not apply.

### Checks

Run launcher and inspect mount diagnostics:

```bash
./cobalt-docker.sh custom.profile
```

Look for:

- `Mount mode: bind|fallback|none`
- `Profile source: ...`

Validate mount source visibility:

```bash
echo "MOUNT_SOURCE=${MOUNT_SOURCE:-$(pwd)}"
test -d "${MOUNT_SOURCE:-$(pwd)}" && echo "mount source exists"
```

### Fix Commands

- Use a Docker-shared mount source for bind mode:

```bash
MOUNT_SOURCE="$HOME/Cobalt-Docker" ./cobalt-docker.sh custom.profile
```

- If platform host detection is unreliable, set explicit runtime host:

```bash
TEAMSERVER_HOST_OVERRIDE=10.42.99.10 ./cobalt-docker.sh custom.profile
```

- For fallback mode, ensure profile exists in image path:

```bash
docker run --rm --entrypoint /bin/sh cobaltstrike:latest -c 'ls -la /opt/cobaltstrike/mount'
```

## Health Verification Troubleshooting

### Symptom

- `/health` endpoint check fails.
- TLS probe returns connection or handshake errors.
- REST API appears started but is unreachable.

### Checks

```bash
REST_API_PORT="${REST_API_PUBLISH_PORT:-50443}"
curl -ksS -o /dev/null -w '%{http_code}\n' "https://127.0.0.1:${REST_API_PORT}/health"
openssl s_client -connect "127.0.0.1:${REST_API_PORT}" -servername localhost -brief </dev/null
lsof -iTCP:"${REST_API_PORT}" -sTCP:LISTEN
```

Expected:

- `curl` returns `2xx`, `401`, or `403` (listener reachable).
- `openssl` negotiates TLS successfully.
- Listener is present on expected port.

### Fix Commands

- Confirm publish mapping and container env:

```bash
docker inspect cobaltstrike_server | rg -n "REST_API_PUBLISH_PORT|SERVICE_PORT|UPSTREAM_PORT|HEALTHCHECK_URL"
```

- Restart container after config correction:

```bash
docker rm -f cobaltstrike_server || true
./cobalt-docker.sh
```

## CI Failure Triage

Use this table to reproduce CI failures locally.

| CI Job | Local Reproduction |
|--------|--------------------|
| `runtime-reliability / syntax-checks` | `bash -n cobalt-docker.sh && bash -n docker-entrypoint.sh` |
| `runtime-reliability / shell-regression-suite` | `./tests/run-shell-tests.sh` |
| `runtime-reliability / secret-scan` | `./scripts/scan-secrets.sh .` |

If local reproduction passes but CI fails, inspect workflow logs for environment/path differences and re-run the exact failing command from the log output.
