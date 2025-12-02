# WARP.md

This file provides guidance to WARP (warp.dev) when working with code in this repository.

## Repository overview

This repository packages a Cobalt Strike team server into a Docker container and provides a small automation script plus a sample Malleable C2 profile. The typical workflow is:

1. Provide a valid Cobalt Strike license key and team server password.
2. Build the Docker image with those credentials baked into the image via a build argument.
3. Run a containerized team server bound to the host, using a malleable profile from the working directory.

## Project structure

- `Dockerfile` – Builds an `ubuntu:latest` (linux/amd64) image with Java, pulls and installs Cobalt Strike using the `COBALTSTRIKE_LICENSE` build arg, runs `./update`, and sets the entrypoint to `./teamserver` in `/opt/cobaltstrike/server`. It exposes common C2 ports and creates `/opt/cobaltstrike/mount` for host mounts.
- `cobalt-docker.sh` – Main automation script. Handles configuration (`.env`), builds the Docker image, detects the host IP (Linux/macOS), validates the chosen malleable profile, and runs the team server container with appropriate port mappings and volume mounts.
- `malleable.profile` – Default Malleable C2 profile mounted into the container and passed to the team server. You can add additional profiles in the repo and select them when running the script.
- `.gitignore` – Ensures `.env` (containing your license key and team server password) is not committed.

## Common commands and workflows

All commands below assume you are in the repository root.

### First-time setup

- Clone and enter the repo:
  - `git clone https://github.com/Maleick/Cobalt-Docker.git`
  - `cd Cobalt-Docker`
- Make the automation script executable:
  - `chmod +x cobalt-docker.sh`

### Build and run the team server (default profile)

This is the main development/usage entrypoint.

- Build the image and start the containerized team server using the default `malleable.profile`:
  - `./cobalt-docker.sh`

On the first run, the script will:

1. Prompt for your Cobalt Strike license key (`COBALTSTRIKE_LICENSE`).
2. Prompt (silently) for the team server password (`TEAMSERVER_PASSWORD`).
3. Persist both values into `.env` with `chmod 600` for reuse.

Subsequent runs will reuse `.env` without prompting.

### Run with a custom Malleable C2 profile

Place your custom profile in the repo root (for example, `profiles/my_profile.profile` copied or moved to the root if needed), then pass it as the first argument:

- `./cobalt-docker.sh custom.profile`

The script will:

- Verify that the given file exists in the current working directory.
- Bind-mount the repository directory into `/opt/cobaltstrike/mount` in the container.
- Pass `/opt/cobaltstrike/mount/custom.profile` as the profile argument to `teamserver`.

### Lint Malleable C2 profiles with c2lint

`cobalt-docker.sh` can run `c2lint` inside the built Docker image against any profile in the repo root:

- Lint the default profile only (no team server):
  - `./cobalt-docker.sh lint`
- Lint a specific profile only (no team server):
  - `./cobalt-docker.sh lint malleable.profile.4.12-drip`
- Lint and then start the team server with a specific profile:
  - `./cobalt-docker.sh malleable.profile.4.12-drip --lint`

If `c2lint` reports errors, the script exits and does not start the team server.

### Rebuild or refresh the Docker image

The script always performs a build before running:

- `docker build --build-arg COBALTSTRIKE_LICENSE="$COBALTSTRIKE_LICENSE" -t cobaltstrike:latest .`

You normally do not need to run this manually, but if you:

- Change the `Dockerfile`, or
- Want to force a clean rebuild,

you can optionally run (from the repo root):

- `docker build --no-cache --build-arg COBALTSTRIKE_LICENSE="$COBALTSTRIKE_LICENSE" -t cobaltstrike:latest .`

### Cleaning up / reconfiguring credentials

- Stop the running container: the script runs the container with `--rm`, so stopping it (e.g., via `docker stop cobaltstrike_server`) removes it automatically. The script also does a defensive `docker rm -f cobaltstrike_server` before starting.
- To re-enter or change credentials, delete the `.env` file and rerun the script:
  - `rm .env`
  - `./cobalt-docker.sh`

### Networking and ports

When the script runs the container, it:

- Detects the host IP:
  - On Linux: first address from `hostname -I`.
  - On macOS: IP from `ifconfig en0`.
- Maps key ports from container to host:
  - `50050/tcp` – Cobalt Strike team server control port.
  - `80/tcp`, `443/tcp` – HTTP/HTTPS C2 listener ports.
  - `53/udp` – DNS (if you choose to use DNS-based listeners, even though the sample profile does not use DNS beacons).

The detected host IP and the team server password are passed as arguments to the `teamserver` entrypoint inside the container.

## Implementation and architecture notes

### Docker image layout and behavior

- Base image: `ubuntu:latest` for `linux/amd64`.
- Installs minimal dependencies for Cobalt Strike: Java 11 (`openjdk-11-jdk`), `curl`, `expect`, and basic tooling.
- Uses the `COBALTSTRIKE_LICENSE` build argument to:
  - Request a download token from `https://download.cobaltstrike.com/download`.
  - Download `cobaltstrike-dist-linux.tgz`.
  - Extract into `/opt/cobaltstrike` and run `./update` with the license piped on stdin.
- Sets `COBALTSTRIKE_HOME=/opt/cobaltstrike`, adds it to `PATH`, and creates `/opt/cobaltstrike/mount` to receive the bind-mounted project directory.
- Exposes a wide set of ports relevant for C2 traffic, but actual host exposure is controlled by the `docker run` flags in `cobalt-docker.sh`.
- Working directory: `/opt/cobaltstrike/server`.
- Entry point: `./teamserver`, so container arguments are interpreted exactly as Cobalt Strike’s team server expects (IP, password, profile).

### `cobalt-docker.sh` responsibilities

`cobalt-docker.sh` is the primary orchestration layer. It coordinates:

1. **Configuration management**
   - Loads existing `.env` if present (`source .env`).
   - Otherwise prompts for `COBALTSTRIKE_LICENSE` and `TEAMSERVER_PASSWORD`, writes them to `.env`, and restricts permissions.
   - Validates that both values are set before continuing.

2. **Image build**
   - Runs `docker build` with `--build-arg COBALTSTRIKE_LICENSE=...` and tags the image as `cobaltstrike:latest`.
   - If the build fails (non-zero exit), the script aborts.

3. **Host IP detection**
   - On Linux: `hostname -I | awk '{print $1}'`.
   - On macOS: `ifconfig en0 | grep "inet " | awk '{print $2}'`.
   - Exits with an error if no IP can be determined.

4. **Profile selection and validation**
   - Uses the first script argument as the profile name, defaulting to `malleable.profile`.
   - Verifies the profile file exists in the current directory.

5. **Container lifecycle**
   - Removes any stale container named `cobaltstrike_server` (`docker rm -f`).
   - Starts a new container with:
     - `--name cobaltstrike_server`.
     - `--mount type=bind,source=$(pwd),target=/opt/cobaltstrike/mount` so that profiles in the repo are visible inside the container.
     - Port mappings for `50050`, `80`, `443`, and `53/udp`.
     - `--rm` so the container is automatically removed when it stops.
     - Arguments: `${IPADDRESS} ${TEAMSERVER_PASSWORD} /opt/cobaltstrike/mount/${PROFILE_NAME}` passed through to `teamserver`.

### Working with Malleable C2 profiles

- The included `malleable.profile` provides a starting point with:
  - A single HTTP profile mimicking a JSON API under `/api/v3/config/...` paths.
  - Customized headers, URIs, and parameters.
  - TLS certificate settings for `update.businessapp9.com`.
  - Various in-memory and injection hardening options (e.g., `sleep_mask`, `beacon_gate`, `process-inject`, `post-ex`).
- To iterate on profiles:
  - Edit `malleable.profile` (or create new profiles) in the repo.
  - Rerun `./cobalt-docker.sh [your_profile.profile]` to restart a container with the updated profile.

## How future Warp instances should use this repo

- Treat `cobalt-docker.sh` as the canonical entrypoint for building and running the environment; do not hand-roll `docker run` commands unless you are intentionally changing behavior.
- When modifying the `Dockerfile` or profile handling, keep the contract that the container’s entrypoint is `./teamserver` in `/opt/cobaltstrike/server` and that profiles live under `/opt/cobaltstrike/mount`.
- When assisting with C2 profile changes, prefer creating or editing `.profile` files in the repo root and invoking them via `./cobalt-docker.sh <profile>` so changes remain transparent and reproducible.
