#!/usr/bin/env bash
# Open another terminal in the running SLAM tutorial container.
# Run from anywhere, as many times as you need:  ./slam_deployment/attach.sh
#
# Environment overrides:
#   CONTAINER_NAME  container name (default: slam_deployment)

set -euo pipefail

CONTAINER_NAME="${CONTAINER_NAME:-slam_deployment}"

if [ -z "$(docker ps -q --filter "name=^${CONTAINER_NAME}$")" ]; then
  echo "error: container '${CONTAINER_NAME}' is not running. Start it first: ./slam_deployment/start.sh" >&2
  exit 1
fi

# ~/.bashrc inside the container sources ROS 2 and the built workspace.
exec docker exec -it --workdir /root/ws "${CONTAINER_NAME}" bash
