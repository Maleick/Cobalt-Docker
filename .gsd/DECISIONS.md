# Decisions Register

<!-- Append-only. Never edit or remove existing rows.
     To reverse a decision, add a new row that supersedes it.
     Read this file at the start of any planning or research phase. -->

| # | When | Scope | Decision | Choice | Rationale | Revisable? |
|---|------|-------|----------|--------|-----------|------------|
| D001 | M001 | arch | LLM integration approach for CS REST API | Pi skill instead of MCP server | REST API already auto-starts in Docker; skill eliminates separate MCP process, reduces operational complexity, keeps everything in repo's existing skill architecture | Yes — if MCP tooling matures to be zero-config |
| D002 | M001 | pattern | Destructive operation handling | No special confirmation gates | Operator reviews and approves at plan level; skill trusts pre-approval, no per-call interrupts | Yes — if operational safety requires it |
| D003 | M001 | scope | Endpoint coverage strategy | Core ops first (6 groups deep, 8 groups light) | Beacons, listeners, tasks, creds, server config, payloads cover ~80% of operational use; remaining 8 groups get reference patterns, deferred to R013 for deep coverage | Yes — when R013 is prioritized |
| D004 | M001 | pattern | Environment detection | Auto-detect from .env for local Docker | Skill reads REST_API_PUBLISH_PORT and REST_API_USER from .env; falls back to prompting for remote deployments | No |
| D005 | M001 | scope | Gemini CI workflows | Remove all 5 workflows + command configs | User confirmed they are no longer needed | No |
| D006 | M001 | pattern | Dockerfile base image | Pin to ubuntu:24.04 | Reproducible builds; CS REST API tested on Ubuntu 22.04 and 24.04 | Yes — on next Ubuntu LTS |
