#!/usr/bin/env bash
# Start the SLAM tutorial container (first terminal).
# Run from anywhere:  ./slam_deployment/start.sh [--gpu]
#
# - Mounts this folder (slam_deployment/) at /root/ws/src.
# - Mounts the host rosbag folder (default ~/rosbags) at /root/bags.
# - Keeps the colcon build/, install/ and log/ folders in named Docker volumes,
#   so the workspace only has to be built once, not on every start.
# - If the container is already running, it opens another shell in it instead.
#
# Options:
#   --gpu           pass the NVIDIA GPU through (needs the NVIDIA Container Toolkit)
#
# Environment overrides:
#   IMAGE_NAME      image to run          (default: slam-tutorial)
#   CONTAINER_NAME  container name        (default: slam_deployment)
#   BAG_DIR         host rosbag folder    (default: ~/rosbags)
#   ROS_DOMAIN_ID   forwarded to the container if set on the host

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
IMAGE_NAME="${IMAGE_NAME:-slam-tutorial}"
CONTAINER_NAME="${CONTAINER_NAME:-slam_deployment}"
BAG_DIR="${BAG_DIR:-$HOME/rosbags}"

GPU_ARGS=()
for arg in "$@"; do
  case "$arg" in
    --gpu) GPU_ARGS=(--gpus all) ;;
    -h|--help) sed -n '2,19p' "$0"; exit 0 ;;
    *) echo "error: unknown option '$arg' (see --help)" >&2; exit 1 ;;
  esac
done

# Already running? Just open another shell in it.
if [ -n "$(docker ps -q --filter "name=^${CONTAINER_NAME}$")" ]; then
  echo ">> '${CONTAINER_NAME}' is already running, opening a new shell in it."
  exec "${SCRIPT_DIR}/attach.sh"
fi

if ! docker image inspect "${IMAGE_NAME}" >/dev/null 2>&1; then
  echo "error: image '${IMAGE_NAME}' not found. Build it first: ./slam_deployment/build_docker.sh" >&2
  exit 1
fi

# A bind mount of a missing folder would be created as root-owned, so create it now.
mkdir -p "${BAG_DIR}"

# Allow the container to open GUI windows (RViz) on the host X server.
if command -v xhost >/dev/null 2>&1 && [ -n "${DISPLAY:-}" ]; then
  xhost +local: >/dev/null
else
  echo ">> warning: no X display found, GUI tools such as RViz will not open." >&2
fi

ENV_ARGS=(--env DISPLAY="${DISPLAY:-}" --env QT_X11_NO_MITSHM=1)
[ -n "${ROS_DOMAIN_ID:-}" ] && ENV_ARGS+=(--env ROS_DOMAIN_ID="${ROS_DOMAIN_ID}")

# Every shell (this one and the ones attach.sh opens) sources the built workspace.
INIT='grep -q "/root/ws/install/setup.bash" ~/.bashrc || echo "[ -f /root/ws/install/setup.bash ] && source /root/ws/install/setup.bash" >> ~/.bashrc; exec bash'

echo ">> Starting '${CONTAINER_NAME}' (source: ${SCRIPT_DIR}, bags: ${BAG_DIR})"
echo ">> Open more terminals with: ./slam_deployment/attach.sh"

# Note: no --hostname here. With --net=host a custom hostname is missing from
# /etc/hosts and ROS 2 (DDS) discovery silently fails.
exec docker run -it --rm \
  --name "${CONTAINER_NAME}" \
  --net=host \
  --ipc=host \
  "${GPU_ARGS[@]}" \
  "${ENV_ARGS[@]}" \
  --volume /tmp/.X11-unix:/tmp/.X11-unix \
  --volume "${SCRIPT_DIR}":/root/ws/src \
  --volume "${BAG_DIR}":/root/bags \
  --volume slam_ws_build:/root/ws/build \
  --volume slam_ws_install:/root/ws/install \
  --volume slam_ws_log:/root/ws/log \
  --workdir /root/ws \
  "${IMAGE_NAME}" \
  bash -c "${INIT}"
