#!/usr/bin/env bash
# Build the SLAM tutorial Docker image (ROS 2 Humble + Ceres, GTSAM, PCL,
# Livox driver, EVO). Run from anywhere:  ./slam_deployment/build_docker.sh
#
# Options:
#   --no-cache      rebuild every layer from scratch
#   any other args  are passed straight to `docker build`
#
# Environment overrides:
#   IMAGE_NAME      image tag to build (default: slam-tutorial)

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
IMAGE_NAME="${IMAGE_NAME:-slam-tutorial}"

if ! command -v docker >/dev/null 2>&1; then
  echo "error: docker is not installed or not on PATH" >&2
  exit 1
fi

echo ">> Building image '${IMAGE_NAME}' from ${SCRIPT_DIR}/Dockerfile"
echo ">> The first build compiles Ceres and GTSAM from source and takes a while."

docker build -t "${IMAGE_NAME}" "$@" "${SCRIPT_DIR}"

echo
echo ">> Done. Start the container with: ./slam_deployment/start.sh"
