#!/bin/bash

# Ensure directories exist and are writable
LOGS_DIR="$(pwd)/logs"
PROJECT_DIR="$(pwd)/project"
mkdir -p "$LOGS_DIR" "$PROJECT_DIR"
chmod -R 777 "$LOGS_DIR" "$PROJECT_DIR"

# Make scripts executable
chmod +x project/scripts/*.sh

IMAGE_NAME="erlang-multi-version"

echo "Building Podman image $IMAGE_NAME..."
podman build -t "$IMAGE_NAME" .

echo "Starting container..."
echo "Shared logs directory: $LOGS_DIR -> /var/log/erlang"
echo "Project directory: $PROJECT_DIR -> /workspace/project"
echo "Inside container, use: /workspace/project/scripts/run_tests.sh [26|28|29]"

# Note: --privileged is required for nested podman/docker
podman run -it --rm \
    --name erlang-dev \
    --privileged \
    -v "$LOGS_DIR:/var/log/erlang:Z" \
    -v "$(pwd):/workspace:Z" \
    "$IMAGE_NAME"
