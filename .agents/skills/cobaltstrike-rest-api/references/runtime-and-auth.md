# Runtime and Authentication

## Local Docker Defaults (`/opt/Cobalt-Docker`)

Use these defaults when the user confirms a local Docker deployment:

- Base URL: `https://127.0.0.1:${REST_API_PUBLISH_PORT}`
- Default published port: `50443`
- Default REST username: `csrestapi` (when `REST_API_USER` is not set)
- Login password: same value as `TEAMSERVER_PASSWORD`
- Internal Team Server link used by REST API: `127.0.0.1:50050`

The local runner publishes the REST API on loopback by default:

- `127.0.0.1:${REST_API_PUBLISH_PORT}:50443`

## Remote Deployment Checklist

Ask for:

1. Base URL (`https://host:port`)
2. TLS certificate behavior (trusted CA, private CA, or self-signed)
3. REST username
4. Team Server password value for login
5. Network reachability from the execution host

## Authentication Flow

### 1) Get token

Endpoint:

- `POST /api/auth/login`

Request body shape:

```json
{
  "username": "<REST_API_USER>",
  "password": "<TEAMSERVER_PASSWORD>",
  "duration_ms": 86400000
}
```

Notes:

- `username` and `password` are required.
- `duration_ms` is optional.
- OpenAPI schema documents a max `duration_ms` of `86400000` milliseconds.

### 2) Use bearer token

Response shape:

```json
{
  "access_token": "<JWT>",
  "token_type": "Bearer",
  "expires_in": 86400000
}
```

Header on protected endpoints:

- `Authorization: Bearer <access_token>`

## Minimal `curl` login example

```bash
BASE_URL="https://127.0.0.1:50443"
API_USER="csrestapi"
API_PASS="<TEAMSERVER_PASSWORD>"

TOKEN="$(curl -sk -X POST "$BASE_URL/api/auth/login" \
  -H "Content-Type: application/json" \
  -d "{\"username\":\"$API_USER\",\"password\":\"$API_PASS\"}" \
  | jq -r '.access_token')"
```

Then use:

```bash
curl -sk "$BASE_URL/api/v1/beacons" \
  -H "Authorization: Bearer $TOKEN"
```

## Common Failures

- `401/403` after login:
  - token missing/expired
  - wrong username/password pairing
- TLS handshake errors:
  - untrusted/self-signed cert on remote host
- Connection refused/timeout:
  - wrong host/port
  - API not published or blocked by firewall

## Authorized Use Boundary

Provide guidance only for authorized testing, sanctioned red-team operations, or approved lab environments.
