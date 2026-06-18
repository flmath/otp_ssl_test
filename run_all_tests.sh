#!/bin/bash
set -e

# Versions to test
VERSIONS=("26" "28" "29" "gmssl")

# Detect orchestration tool
if command -v podman &> /dev/null; then
    ORCHESTRATOR="podman"
elif command -v docker &> /dev/null; then
    if docker compose version &> /dev/null; then
        ORCHESTRATOR="docker compose"
    else
        ORCHESTRATOR="docker-compose"
    fi
else
    echo "Error: No container tool found (podman or docker)."
    exit 1
fi

echo "Using $ORCHESTRATOR for orchestration."

CONTAINER_NAME="erlang-dev"
IMAGE_NAME="erlang-multi-version"

echo "Starting Erlang TLS Test Orchestrator..."
echo "Building image $IMAGE_NAME..."

if [ "$ORCHESTRATOR" == "podman" ]; then
    podman build -t "$IMAGE_NAME" .
    
    echo "Stopping/Removing existing container..."
    podman stop "$CONTAINER_NAME" &> /dev/null || true
    podman rm "$CONTAINER_NAME" &> /dev/null || true
    
    echo "Starting container with host networking..."
    # Using --net=host is crucial for restricted environments (Incus/LXD)
    # where aardvark/netavark networking often fails.
    podman run --name "$CONTAINER_NAME" -d \
        -v /workspace:/workspace:Z \
        -v /workspace/logs:/var/log/erlang:Z \
        --net=host \
        -w /workspace \
        "$IMAGE_NAME" /bin/bash -c "sleep infinity"
    
    CONTAINER_ID="$CONTAINER_NAME"
else
    # Docker/Docker-Compose path
    $ORCHESTRATOR up -d --build
    echo "Waiting for environment to stabilize..."
    sleep 5
    CONTAINER_ID=$($ORCHESTRATOR ps -q erlang-dev)
fi

if [ -z "$CONTAINER_ID" ]; then
    echo "Error: Could not find or start the $CONTAINER_NAME container."
    exit 1
fi

echo "Found container: $CONTAINER_ID"

for VERSION in "${VERSIONS[@]}"; do
    echo ""
    echo "################################################"
    echo "Running tests for Erlang version: $VERSION"
    echo "################################################"
    
    if [ "$ORCHESTRATOR" == "podman" ]; then
        podman exec -i "$CONTAINER_ID" /workspace/project/scripts/run_tests.sh "$VERSION"
    else
        docker exec -i "$CONTAINER_ID" /workspace/project/scripts/run_tests.sh "$VERSION"
    fi
done

echo ""
echo "All tests completed. Detailed logs are in ./logs"
if [ "$ORCHESTRATOR" != "podman" ]; then
    echo "To stop, run: $ORCHESTRATOR down"
else
    echo "To stop, run: podman stop $CONTAINER_NAME"
fi
