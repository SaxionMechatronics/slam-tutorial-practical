# SLAM Tutorial

![ROS 2 Humble](https://img.shields.io/badge/ROS%202-Humble-22314E?logo=ros&logoColor=white)
![Ubuntu 22.04](https://img.shields.io/badge/Ubuntu-22.04-E95420?logo=ubuntu&logoColor=white)
![Docker](https://img.shields.io/badge/Docker-ready-2496ED?logo=docker&logoColor=white)

A hands-on deployment workspace for running and comparing LiDAR-Inertial and Visual-Inertial SLAM packages on **ROS 2 Humble**, packaged in a reproducible Docker environment. Everything the algorithms need ROS 2, Ceres, GTSAM, PCL, the Livox driver and the [EVO](https://github.com/MichaelGrupp/evo) evaluation
toolkit is baked into a single image, so no SLAM dependencies have to be installed on the host.

This README currently documents the **[Fast-LIMO](https://github.com/fetty31/fast_LIMO)** (Fast LiDAR-Inertial Mapping & Odometry) pipeline. The other packages bundled in this repository are listed under [Included packages](#included-packages) and will be documented later.

## Table of Contents

- [About](#about)
- [Included packages](#included-packages)
  - [Repository layout](#repository-layout)
- [Prerequisites](#prerequisites)
- [Clone & build](#clone--build)
- [Using the Docker container](#using-the-docker-container)
  - [Option A : VS Code Dev Container](#option-a--vs-code-dev-container)
  - [Option B : Plain Docker CLI](#option-b--plain-docker-cli)
- [Running Fast-LIMO](#running-fast-limo)
  - [Configuration](#configuration)
  - [Launch](#launch)
  - [Playing a rosbag](#playing-a-rosbag)
  - [Host ↔ container communication](#host--container-communication)
- [Troubleshooting](#troubleshooting)

## About

The workspace bundles several SLAM implementations as git submodules and provides a single Docker image that contains all of their build and runtime dependencies.
The pattern is deliberate:

- **The Docker image provides the *environment* :** Ubuntu 22.04, ROS 2 Humble and the heavy native dependencies (Ceres, GTSAM, PCL, Livox driver, EVO).

- **The cloned repository provides the *source* :** The SLAM packages, which are bind-mounted into the container and compiled there with `colcon`.

>Because the source lives on the host and is mounted into the container, you can edit code with your normal editor and simply rebuild inside the container.

## Included packages

| Package | Type | Documented here |
|---|---|---|
| **fast_LIMO** | LiDAR-Inertial Odometry & Mapping | Yes |
| FAST_LIO_ROS2 | LiDAR-Inertial Odometry | No |
| LeGO-LOAM-ROS2 | LiDAR Odometry & Mapping | No |
| VINS-Fusion-ROS2 | Visual-Inertial Odometry | No |

### Repository layout

```
slam-tutorial-practical/
├── slam_deployment/
│   ├── Dockerfile            # ROS 2 Humble + all SLAM dependencies + EVO
│   ├── requirements.txt      # Python deps for EVO (trajectory evaluation)
│   ├── .devcontainer/        # VS Code Dev Container definition
│   ├── fast_LIMO/            # submodule (branch: ros2-humble)
│   ├── FAST_LIO_ROS2/        # submodule
│   ├── LeGO-LOAM-ROS2/       # submodule
│   └── VINS-Fusion-ROS2/     # submodule
└── callibration/             # sensor calibration workspaces (Kalibr, LiDAR-IMU)
```

## Prerequisites

Installed on the **host** machine:

- [Docker Engine](https://docs.docker.com/engine/install/)

- `git` : `sudo apt install git`

- An X server for GUI tools such as RViz (already present on most Linux desktops)

>You do **not** need to install ROS 2 or any SLAM dependency on the host those live inside the image.

## Clone & build

#### 1. Clone the repository

`git clone` creates the project folder for you; just run it from wherever you
keep your projects (e.g. `~/Documents`):

```bash
git clone https://github.com/SaxionMechatronics/slam-tutorial-practical
cd slam-tutorial-practical
```

#### 2. Initialise the submodules

The SLAM packages are git submodules, so they must be fetched **on the host**

```bash
git submodule update --init --recursive
```

### 3. Build the Docker image

```bash
cd slam_deployment
docker build -t slam-tutorial .
```

>The first build takes a while (it compiles Ceres and GTSAM from source). Later builds are cached.

# Using the Docker container

There are two supported ways to get a shell inside the environment. Both mount
the `slam_deployment` folder to `/root/ws/src` inside the container.

### Option A : VS Code Dev Container

The repository ships a Dev Container definition under `slam_deployment/.devcontainer/`.

1. Install the **Dev Containers** extension in VS Code.
2. Open the `slam_deployment` folder in VS Code.
3. Run **Dev Containers: Reopen in Container** from the command palette.

>VS Code builds the image, mounts the workspace at `/root/ws/src`, and runs the initial `colcon build` automatically via the container's `postCreateCommand`.

### Option B : Plain Docker CLI

Allow the container to open GUI windows (RViz), then start it with the source folder mounted:

```bash
# from the repo root
xhost +local:            # allow local containers to use the X server

cd slam_deployment
docker run -it --rm \
  --name slam_deployment \
  --net=host \
  --env DISPLAY=$DISPLAY \
  --env QT_X11_NO_MITSHM=1 \
  --volume /tmp/.X11-unix:/tmp/.X11-unix \
  --volume "$PWD":/root/ws/src \
  slam-tutorial
```

Then, **inside the container**, build the workspace once:

```bash
cd /root/ws
source /opt/ros/humble/setup.bash
colcon build --symlink-install
source install/setup.bash
```

> Add `--gpus all` to the `docker run` command if you have the NVIDIA Container
> Toolkit installed and want GPU access.

> **Container naming:** `--name slam_deployment` gives the container a stable name,
> so you can always attach with `docker exec -it slam_deployment bash` instead of
> looking up a random name. Do **not** add `--hostname` together with `--net=host`:
> the custom hostname is not in the container's `/etc/hosts`, which breaks ROS 2
> (DDS) discovery. See [Troubleshooting](#troubleshooting).

## Running Fast-LIMO

The steps below are run **inside the container**, with the workspace already built and sourced (`source /root/ws/install/setup.bash`).

#### Launch

```bash
# without RViz
ros2 launch fast_limo fast_limo.launch.py

# with RViz visualization
ros2 launch fast_limo fast_limo.launch.py rviz:=True
```

#### Playing a rosbag

Fast-LIMO relies heavily on point-cloud and IMU timestamps, so play recorded data with simulated time and the clock published:

```bash
# container terminal 1 : the SLAM node
ros2 launch fast_limo fast_limo.launch.py rviz:=True

# host terminal  : the rosbag
ros2 bag play <your_bag> --clock
```

Set `use_sim_time` accordingly when replaying recorded data.

> **Tip:** to open another shell in the running container, use
> `docker exec -it slam_deployment bash` and re-source the workspace with
> `source /root/ws/install/setup.bash`.

#### Host container communication

>The container runs with `--net=host`, so it shares the host's network stack. ROS 2 has no central master, nodes discover each other automatically over DDS, so the container and the host behave like two terminals on the same machine. This means you can play the rosbag **either place**:

Two things must match on both sides for discovery to work:

- **`ROS_DOMAIN_ID`** : nodes only find peers on the same domain (default `0`).
- **`ROS_LOCALHOST_ONLY`** : keep it consistent; unset it on both sides if discovery misbehaves.

## Troubleshooting

- **`packages not found` :** The workspace has not been built or sourced. Run `colcon build --symlink-install` in `/root/ws`, then `source /root/ws/install/setup.bash`.

- **Empty submodule folders :** The submodules were not initialised on the host. Run `git submodule update --init --recursive` in the repository root and restart the container.

- **`ros2 topic list` is empty / nodes don't discover each other :** First restart the discovery daemon, which caches results and can go stale after a network change: `ros2 daemon stop` (it restarts on the next command). Then confirm `ROS_DOMAIN_ID` matches on both sides and the container runs with `--net=host`.

- **RViz / GUI window does not appear :** Run `xhost +local:` on the host before starting the container, and make sure `DISPLAY` is forwarded.
