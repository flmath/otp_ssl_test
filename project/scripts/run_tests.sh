#!/bin/bash
set -e

if [ -z "$1" ]; then
  echo "Usage: ./run_tests.sh [26|28|29]"
  exit 1
fi

VERSION=$1
echo "=========================================="
echo "Testing with Erlang $VERSION"
echo "=========================================="

# Switch Erlang version
source /usr/local/bin/switch-erlang.sh $VERSION

# Setup paths
PROJECT_ROOT="/workspace/project"
cd "$PROJECT_ROOT"
mkdir -p ebin certs

# Compile the TLS server
erlc -o ebin src/tls_server.erl

# Run Common Test
# -pa ebin: Adds the compiled server to the code path
# -logdir /var/log/erlang: Stores test logs in the shared host directory
ct_run -dir test -pa "$PROJECT_ROOT/ebin" -logdir /var/log/erlang

echo "=========================================="
echo "Tests for Erlang $VERSION completed."
echo "Check /workspace/logs/ on host for detailed CT reports."
echo "=========================================="
