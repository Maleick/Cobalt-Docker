#!/bin/bash

#
# This script builds and runs the Cobalt Strike Docker container.
#

# --- Configuration ---
# Name for the Docker image and container
DOCKER_IMAGE_NAME="cobaltstrike"
DOCKER_CONTAINER_NAME="cobaltstrike_server"
CONFIG_FILE=".env"

# Directory of this script. We use this as the default bind-mount source so
# Docker always sees the repository contents, even if the script is invoked
# from another working directory.
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# Allow override via environment variable if Docker cannot access SCRIPT_DIR
# (e.g., on macOS when /opt is not shared with the Docker backend).
MOUNT_SOURCE="${COBALT_DOCKER_MOUNT_SOURCE:-$SCRIPT_DIR}"

# --- Argument Parsing ---
# Usage patterns:
#   ./cobalt-docker.sh                      # build + run with default malleable.profile
#   ./cobalt-docker.sh custom.profile       # build + run with custom profile
#   ./cobalt-docker.sh --lint               # build + lint default profile (no run)
#   ./cobalt-docker.sh lint [profile]       # build + lint only
#   ./cobalt-docker.sh custom.profile --lint# build + lint + run

PROFILE_NAME="malleable.profile"
DO_LINT=false
LINT_ONLY=false

while [[ $# -gt 0 ]]; do
    case "$1" in
        --lint)
            DO_LINT=true
            shift
            ;;
        lint)
            DO_LINT=true
            LINT_ONLY=true
            shift
            ;;
        *)
            PROFILE_NAME="$1"
            shift
            ;;
    esac
done

# --- Script Logic ---

# 1. Load or prompt for configuration
if [ -f "$CONFIG_FILE" ]; then
    echo "==> Found existing configuration file. Loading settings..."
    source "$CONFIG_FILE"
else
    echo "==> No configuration file found. Prompting for new settings..."
    # Prompt for License Key
    read -p "==> Enter Cobalt Strike License Key: " COBALTSTRIKE_LICENSE
    if [ -z "$COBALTSTRIKE_LICENSE" ]; then
        echo "Error: A license key is required."
        exit 1
    fi

    # Prompt for Team Server Password
    read -s -p "==> Enter Team Server Password: " TEAMSERVER_PASSWORD
    echo

    # Save to config file
    echo "==> Saving settings to $CONFIG_FILE for future runs..."
    (
        echo "COBALTSTRIKE_LICENSE="$COBALTSTRIKE_LICENSE""
        echo "TEAMSERVER_PASSWORD="$TEAMSERVER_PASSWORD""
    ) > "$CONFIG_FILE"
    chmod 600 "$CONFIG_FILE"
fi

# Validate that variables are set
if [ -z "$COBALTSTRIKE_LICENSE" ] || [ -z "$TEAMSERVER_PASSWORD" ]; then
    echo "Error: License key and password must be set."
    echo "Please check your $CONFIG_FILE or remove it to re-configure."
    exit 1
fi

# 2. Build the Docker image.
#    This will use the Dockerfile in the current directory.
echo "==> Building the Docker image ($DOCKER_IMAGE_NAME)..."
docker build --build-arg COBALTSTRIKE_LICENSE="$COBALTSTRIKE_LICENSE" -t "$DOCKER_IMAGE_NAME":latest .

# Check if the build was successful
if [ $? -ne 0 ]; then
    echo "Error: Docker image build failed."
    exit 1
fi

# 3. Validate that the selected profile exists next to this script (repo root).
if [ ! -f "$SCRIPT_DIR/$PROFILE_NAME" ]; then
    echo "Error: Malleable C2 profile not found at: $SCRIPT_DIR/$PROFILE_NAME"
    exit 1
fi

echo "==> Using Malleable C2 Profile: $PROFILE_NAME"

# Ensure the bind mount source directory exists from the perspective of the
# Docker daemon. On macOS with Docker Desktop/OrbStack this usually means the
# path must live under a directory that is shared with Docker (for example
# somewhere under $HOME). If needed, set COBALT_DOCKER_MOUNT_SOURCE to an
# alternate path and re-run this script.
if [ ! -d "$MOUNT_SOURCE" ]; then
    echo "Error: Docker bind mount source directory does not exist for this Docker context: $MOUNT_SOURCE"
    echo "Hint: On macOS, move the repo under a shared path (e.g. ~/Cobalt-Docker) or set COBALT_DOCKER_MOUNT_SOURCE to a shared directory."
    exit 1
fi

# 4. Optionally lint the profile with c2lint inside the Docker image.
if [ "$DO_LINT" = true ]; then
    echo "==> Running c2lint against $PROFILE_NAME inside Docker image..."
    docker run --rm \
      --mount type=bind,source="$MOUNT_SOURCE",target=/opt/cobaltstrike/mount \
      "$DOCKER_IMAGE_NAME":latest \
      /bin/bash -lc "cd /opt/cobaltstrike/server && ./c2lint /opt/cobaltstrike/mount/$PROFILE_NAME"

    LINT_EXIT_CODE=$?
    if [ $LINT_EXIT_CODE -ne 0 ]; then
        echo "Error: c2lint reported issues with profile $PROFILE_NAME (exit code $LINT_EXIT_CODE)."
        exit $LINT_EXIT_CODE
    fi

    if [ "$LINT_ONLY" = true ]; then
        echo "==> Lint-only mode complete. Not starting team server."
        exit 0
    fi
fi

# 5. Detect the operating system and get the host's primary IP address.
OS="$(uname)"
if [[ "$OS" == "Linux" ]]; then
    IPADDRESS=$(hostname -I | awk '{print $1}')
elif [[ "$OS" == "Darwin" ]]; then # macOS
    IPADDRESS=$(ifconfig en0 | grep "inet " | awk '{print $2}')
else
    echo "Unsupported OS: $OS"
    exit 1
fi

if [ -z "$IPADDRESS" ]; then
    echo "Error: Could not determine the host IP address."
    exit 1
fi

echo "==> Detected Host IP: $IPADDRESS"

# 6. Run the Docker container.
echo "==> Starting Cobalt Strike Docker container ($DOCKER_CONTAINER_NAME)..."
docker rm -f "$DOCKER_CONTAINER_NAME" >/dev/null 2>&1 || true
docker run --name "$DOCKER_CONTAINER_NAME" \
  --mount type=bind,source="$MOUNT_SOURCE",target=/opt/cobaltstrike/mount \
  -p 50050:50050 \
  -p 80:80 \
  -p 443:443 \
  -p 53:53/udp \
  --rm \
  "$DOCKER_IMAGE_NAME":latest \
  "$IPADDRESS" \
  "$TEAMSERVER_PASSWORD" \
  "/opt/cobaltstrike/mount/$PROFILE_NAME"
