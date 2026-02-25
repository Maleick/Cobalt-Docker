---
name: cobaltstrike-rest-api
description: Guide users through Cobalt Strike REST API authentication, endpoint usage, and troubleshooting with source-backed mappings between goals, console actions, and REST endpoints. Use when users ask how to call Cobalt Strike API endpoints, script beacon/listener/task workflows, debug token/login issues, or adapt local Docker versus remote Team Server API deployments.
---

# Cobalt Strike REST API

Use this skill to deliver concise, cited API guidance for authorized Cobalt Strike operations.

## Required First Question

Ask this exact question before giving endpoint instructions:

`Is your Cobalt Strike instance running locally in Docker, or on another host?`

Do not skip this question.

## Workflow

1. Identify runtime location.
- If local Docker, apply defaults from `references/runtime-and-auth.md`.
- If remote, ask for base URL, TLS/certificate behavior, and auth reachability.
2. Establish authentication.
- Start with `POST /api/auth/login`.
- Reuse `Authorization: Bearer <access_token>` for `/api/v1/*` endpoints.
- Mention token lifetime handling (`duration_ms`, renewal).
3. Map user goal to endpoint group.
- Load `references/endpoint-catalog.md`.
- Explain what each endpoint does before showing commands.
4. Provide minimal execution examples.
- Prefer `curl` first.
- Keep secrets and IDs as placeholders.
5. Explain asynchronous task handling.
- For command endpoints, check task summary/details and task `log`/`error`.
6. Cite sources.
- Include links from `references/sources.md`.
7. Enforce authorized-use boundaries.
- Keep guidance for authorized testing and approved operations only.

## Endpoint Group Quick Map

- Security login: `/api/auth/login`
- API root/config: `/api/v1`, `/api/v1/config/*`
- Listener lifecycle: `/api/v1/listeners*`
- Beacon inventory/state/actions: `/api/v1/beacons*`
- Task tracking: `/api/v1/tasks*`
- Evidence/artifacts: `/api/v1/data/*`, `/api/v1/payloads*`, `/api/v1/artifacts`

## Reference Loading Guide

- Load `references/runtime-and-auth.md` when environment, auth, or TLS behavior matters.
- Load `references/endpoint-catalog.md` when mapping user intent to endpoint operations.
- Load `references/agent-usage-patterns.md` when asked how agents should orchestrate the API.
- Load `references/sources.md` for citations and version checks.

## Response Quality Checks

Before finalizing a response, verify:

- First question about local Docker vs remote was asked.
- Auth flow includes `/api/auth/login` and bearer token usage.
- Endpoint recommendations explain what each endpoint does.
- At least one source citation link is present.
- Secrets remain placeholders and are never requested in plain text.
