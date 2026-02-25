# Agent Usage Patterns for Cobalt Strike API

Use these patterns when users ask how agents should orchestrate Cobalt Strike operations through the REST API.

## 1) Beacon Inventory + Filter + Task Dispatch

### Preconditions

- Valid bearer token is available.
- Operator has authorized scope for beacon actions.
- Filter criteria are defined (host, user, process, callback metadata, note tags, or status).

### Sequence

1. `GET /api/v1/beacons` to load current beacons.
2. Apply filter logic in agent memory.
3. Confirm target `bid` set with user when ambiguity exists.
4. Dispatch selected operation using relevant endpoint (for example `POST /api/v1/beacons/{bid}/execute/ls`).
5. Store returned task identifiers for tracking.

### Failure Handling

- Empty beacon list: return "no eligible beacons" and stop.
- Multiple matches: request explicit target selection.
- Dispatch failure (`4xx/5xx`): report endpoint, status code, and request shape used.

## 2) Task Status + Log + Error Polling Loop

### Preconditions

- At least one `taskId` exists from a prior action.

### Sequence

1. Poll `GET /api/v1/tasks/{taskId}` on an interval.
2. Stop polling on terminal status (`COMPLETED`, `FAILED`, or final `OUTPUT_RECEIVED`).
3. Fetch `GET /api/v1/tasks/{taskId}/log`.
4. Fetch `GET /api/v1/tasks/{taskId}/error`.
5. Merge state + log + error into one agent result object.

### Failure Handling

- Timeout threshold reached: return partial status with last known state.
- `NOT_FOUND`: verify task ID and token scope, then retry once.
- Log retrieval fails: still return status and error channel details.

## 3) Listener Lifecycle Management

### Preconditions

- Listener type and intended name are provided.
- Required listener configuration fields are known.

### Sequence

1. `GET /api/v1/listeners` to check name collisions and current state.
2. `POST /api/v1/listeners/<type>` to create listener.
3. `GET /api/v1/listeners/{name}` to verify persisted configuration.
4. `PUT /api/v1/listeners/<type>/{name}` for controlled updates.

### Failure Handling

- Name collision: choose update path or require new name.
- Validation failure: return schema mismatch details and required fields.
- Post-create verification mismatch: mark listener as non-compliant and halt chained steps.

## 4) Evidence Collection Pipeline (Downloads, Screenshots, Keystrokes)

### Preconditions

- Authorized evidence collection scope is approved.
- Target beacon/task context exists.

### Sequence

1. Trigger collection action via beacon command endpoint if needed.
2. Query collection indexes:
   - `GET /api/v1/data/downloads`
   - `GET /api/v1/data/screenshots`
   - `GET /api/v1/data/keystrokes`
3. Retrieve specific evidence records by ID.
4. Attach metadata (beacon, task, timestamps, command context).
5. Produce normalized evidence bundle for downstream analysis.

### Failure Handling

- No new evidence: return empty-but-successful collection state.
- Partial retrieval: mark missing IDs and continue with available records.
- Sensitive-data policy trigger: redact and notify according to policy.

## Implementation Notes for Agent Authors

- Keep authentication handling centralized; do not scatter token refresh logic.
- Always map user intent to endpoint purpose first, then execute.
- Prefer idempotent reads (`GET`) before mutating calls (`POST`/`PUT`).
- Persist request IDs, task IDs, and timestamps to support auditability.
