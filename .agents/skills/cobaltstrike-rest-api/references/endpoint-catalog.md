# Endpoint Catalog (What Each Endpoint Does)

Use this catalog to explain endpoint purpose before giving command examples.

## Security

- `POST /api/auth/login`
  - Generates the bearer token used for authenticated API access.
  - Request body includes `username`, `password`, optional `duration_ms`.
  - Response returns `access_token`, `token_type`, and optional expiration metadata.

## API Root and Server Configuration

- `GET /api/v1`
  - API entry-point health/discovery endpoint.
- `GET /api/v1/config/teamserverIp`
  - Returns Team Server IP configuration.
- `GET /api/v1/config/systeminformation`
  - Returns system information for server context.
- `GET /api/v1/config/profile`
  - Returns profile-related server configuration.
- `GET /api/v1/config/killdate`
  - Returns configured kill date details.

## Listener Lifecycle

- `GET /api/v1/listeners`
  - Lists current listeners.
- `GET /api/v1/listeners/{name}`
  - Fetches one listener by name.
- `POST /api/v1/listeners/<type>`
  - Creates a listener of the specified type (`http`, `https`, `dns`, `smb`, `tcp`, and others defined in OpenAPI).
- `PUT /api/v1/listeners/<type>/{name}`
  - Updates listener configuration.

Typical responses:

- Listener DTO objects containing configuration and status/error fields.

## Beacon Inventory and State

- `GET /api/v1/beacons`
  - Lists active or known beacons.
- `GET /api/v1/beacons/{bid}`
  - Returns details for one beacon.
- `GET /api/v1/beacons/{bid}/tasks/summary`
  - Lists summarized tasks associated with beacon.
- `GET /api/v1/beacons/{bid}/tasks/detail`
  - Returns detailed task records for beacon.
- `GET /api/v1/beacons/{bid}/state/jobs`
  - Lists active jobs for beacon.
- `GET /api/v1/beacons/{bid}/help`
  - Returns available console commands.
- `GET /api/v1/beacons/{bid}/help/{command}`
  - Returns command-specific help.

Common command families:

- `POST /api/v1/beacons/{bid}/execute/*`
- `POST /api/v1/beacons/{bid}/spawn/*`
- `POST /api/v1/beacons/{bid}/inject/*`
- `POST /api/v1/beacons/{bid}/remoteExec/*`
- `POST /api/v1/beacons/{bid}/elevate/*`

Each action endpoint maps to a specific command behavior documented in OpenAPI and in the console command mapping table.

## Task Tracking and Result Retrieval

- `GET /api/v1/tasks`
  - Lists tasks (summary view).
- `GET /api/v1/tasks/{taskId}`
  - Returns detailed task state and optional formatted output.
- `GET /api/v1/tasks/{taskId}/log`
  - Returns command/log output for task.
- `GET /api/v1/tasks/{taskId}/error`
  - Returns error output for task.

Typical async flow:

1. Submit an action endpoint (for example `execute/*`).
2. Capture returned task metadata (task identifiers).
3. Poll `GET /api/v1/tasks/{taskId}` until terminal state.
4. Retrieve `log` and `error` to finalize output.

Task status values in schema include:

- `IN_PROGRESS`
- `COMPLETED`
- `FAILED`
- `OUTPUT_RECEIVED`
- `NOT_FOUND`

## Data and Evidence Endpoints

- `GET /api/v1/data/downloads`
  - Lists file downloads captured on Team Server.
- `GET /api/v1/data/downloads/{id}`
  - Retrieves specific download content/record.
- `GET /api/v1/data/screenshots`
  - Lists screenshot records.
- `GET /api/v1/data/screenshots/{id}`
  - Retrieves a specific screenshot.
- `GET /api/v1/data/keystrokes`
  - Lists captured keystroke data.
- `GET /api/v1/data/keystrokes/{id}`
  - Retrieves specific keystroke record.
- `GET /api/v1/data/credentials`
  - Lists credential entries.
- `GET /api/v1/data/credentials/{id}`
  - Retrieves one credential record.

## Payload and Artifact Endpoints

- `POST /api/v1/payloads/generate/stager`
  - Generates stager payload artifacts server-side.
- `POST /api/v1/payloads/generate/stageless`
  - Generates stageless payload artifacts server-side.
- `GET /api/v1/payloads/{fileName}`
  - Retrieves generated payload file.
- `GET /api/v1/artifacts`
  - Lists available server-side artifacts.

## Response Shape Notes

- Action endpoints often return async command metadata, not immediate command output.
- Task detail and task log/error endpoints are the authoritative source for completion and result content.
- Resource listing endpoints generally return arrays of typed DTO objects documented in OpenAPI.
