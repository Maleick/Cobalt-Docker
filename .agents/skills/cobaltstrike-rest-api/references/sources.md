# Sources

Use these as primary citation targets when answering.

## Official Cobalt Strike Documentation

- REST API index (interactive Swagger UI):  
  https://hstechdocs.helpsystems.com/manuals/cobaltstrike/current/userguide/content/api/index.html
- OpenAPI spec payload (`spec.js`):  
  https://hstechdocs.helpsystems.com/manuals/cobaltstrike/current/userguide/content/api/spec.js
- Console command mapping page (includes equivalent REST endpoint links):  
  https://hstechdocs.helpsystems.com/manuals/cobaltstrike/current/userguide/content/topics/post-exploitation_running-commands.htm#Beacon

## Local Runtime Reference

- Local Docker runtime and API publish defaults:  
  `/opt/Cobalt-Docker/README.md`
- Local Docker launcher behavior and environment variables:  
  `/opt/Cobalt-Docker/cobalt-docker.sh`
- Container startup wiring for `teamserver` + `csrestapi`:  
  `/opt/Cobalt-Docker/docker-entrypoint.sh`

## Version Notes

- The cited Cobalt Strike docs currently present version metadata for 4.12 and a December 2025 publication stamp.
- Treat endpoint availability as version-sensitive and verify against `spec.js` for each session when accuracy is critical.
