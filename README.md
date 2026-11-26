# SLAM Tutorial

![ROS 2 Humble](https://img.shields.io/badge/ROS%202-Humble-22314E?logo=ros&logoColor=white) ![Ubuntu 22.04](https://img.shields.io/badge/Ubuntu-22.04-E95420?logo=ubuntu&logoColor=white) ![Docker](https://img.shields.io/badge/Docker-ready-2496ED?logo=docker&logoColor=white)

A hands-on deployment workspace for running and comparing LiDAR-Inertial and Visual-Inertial SLAM packages on **ROS 2 Humble**, packaged in a reproducible Docker environment. Everything the algorithms need (ROS 2, Ceres, GTSAM, PCL, the Livox driver and the [EVO](https://github.com/MichaelGrupp/evo) evaluation toolkit) is baked into a single image, so no SLAM dependencies have to be installed on the host.

The README documents how to build and run each of the bundled pipelines, one section per package: **[Fast-LIMO](https://github.com/fetty31/fast_LIMO)**, **[FAST-LIO](https://github.com/hku-mars/FAST_LIO)**, **[LeGO-LOAM](https://github.com/RobustFieldAutonomyLab/LeGO-LOAM)** and **[VINS-Fusion](https://github.com/HKUST-Aerial-Robotics/VINS-Fusion)**.

## Table of Contents

- [About](#about)
- [Included packages](#included-packages)
  - [Repository layout](#repository-layout)
- [Prerequisites](#prerequisites)
- [Clone the repository](#1-clone-the-repository)
- [Build the Docker image](#2-build-the-docker-image)
- [Start the container](#3-start-the-container)
  - [Opening more terminals](#opening-more-terminals)
  - [Alternative: VS Code Dev Container](#alternative-vs-code-dev-container)
- [Build the SLAM packages](#4-build-the-slam-packages)
- [Launch the sensors or play a rosbag](#5-launch-the-sensors-or-play-a-rosbag)
  - [Option A: Live sensors](#option-a-live-sensors)
  - [Option B: Play a rosbag](#option-b-play-a-rosbag)
  - [Zenoh-recorded rosbags (rmw_zenoh)](#zenoh-recorded-rosbags-rmw_zenoh)
- [Run a SLAM package](#6-run-a-slam-package)
  - [Fast-LIMO](#fast-limo)
  - [FAST-LIO](#fast-lio)
  - [LeGO-LOAM](#lego-loam)
  - [VINS-Fusion](#vins-fusion)
- [Host ↔ container communication](#host--container-communication)
- [Troubleshooting](#troubleshooting)

## About

The workspace bundles several SLAM implementations as git submodules and provides a single Docker image that contains all of their build and runtime dependencies.
The pattern is deliberate:

- **The Docker image provides the *environment* :** Ubuntu 22.04, ROS 2 Humble and the heavy native dependencies (Ceres, GTSAM, PCL, Livox driver, EVO).

- **The cloned repository provides the *source* :** The SLAM packages, which are bind-mounted into the container and compiled there with `colcon`.

>Because the source lives on the host and is mounted into the container, you can edit code with your normal editor and simply rebuild inside the container.

## Included packages

| Package | Type | ROS 2 package(s) | Run instructions |
|---|---|---|---|
| **fast_LIMO** | LiDAR-Inertial Odometry & Mapping | `fast_limo` | [Fast-LIMO](#fast-limo) |
| **FAST_LIO_ROS2** | LiDAR-Inertial Odometry | `fast_lio` | [FAST-LIO](#fast-lio) |
| **LeGO-LOAM-ROS2** | LiDAR Odometry & Mapping | `lego_loam_sr` | [LeGO-LOAM](#lego-loam) |
| **VINS-Fusion-ROS2** | Visual-Inertial Odometry | `vins`, `loop_fusion`, `global_fusion`, `camera_models` | [VINS-Fusion](#vins-fusion) |

### Repository layout

```
slam-tutorial-practical/
├── slam_deployment/
│   ├── build_docker.sh       # builds the Docker image
│   ├── start.sh              # starts the container (first terminal)
│   ├── attach.sh             # opens another terminal in the running container
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

>You do **not** need to install ROS 2 or any SLAM dependency on the host, those live inside the image.

## 1. Clone the repository

Clone the projects. `--recursive` also fetches the SLAM packages, which are git submodules:

```bash
git clone --recursive https://github.com/SaxionMechatronics/slam-tutorial-practical
cd slam-tutorial-practical
```

If you already cloned without `--recursive`, fetch the submodules afterwards (on the **host**):

```bash
git submodule update --init --recursive
```

**Fetch only the package(s) you need.** `git submodule update --init` accepts explicit submodule paths, so you can pull just one algorithm and leave the rest as empty folders:

```bash
# only Fast-LIMO
git submodule update --init --recursive slam_deployment/fast_LIMO

# a subset : list several paths
git submodule update --init --recursive slam_deployment/fast_LIMO slam_deployment/VINS-Fusion-ROS2
```

| Package | Submodule path |
|---|---|
| fast_LIMO | `slam_deployment/fast_LIMO` |
| FAST_LIO_ROS2 | `slam_deployment/FAST_LIO_ROS2` |
| LeGO-LOAM-ROS2 | `slam_deployment/LeGO-LOAM-ROS2` |
| VINS-Fusion-ROS2 | `slam_deployment/VINS-Fusion-ROS2` |

> Run `git submodule status` to see which are initialised.

---
## 2. Build the Docker image

From the repository root:

```bash
./slam_deployment/build_docker.sh
```

This builds the image `slam-tutorial` from `slam_deployment/Dockerfile`. Extra arguments are passed to `docker build`, e.g. `./slam_deployment/build_docker.sh --no-cache` for a clean rebuild.

>The first build takes a while (it compiles Ceres and GTSAM from source). Later builds are cached.

---
## 3. Start the container

```bash
./slam_deployment/start.sh
```

This is your **first terminal**, and it is now a shell inside the container at `/root/ws`. The script:

- allows the container to open GUI windows (`xhost +local:`), for RViz;
- mounts `slam_deployment/` at `/root/ws/src`, so code edits on the host show up immediately;
- mounts the host's `~/rosbags` folder at `/root/bags` (created if missing);
- runs with `--net=host` and `--ipc=host`, so ROS 2 nodes on the host and in the container see each other;
- keeps `build/`, `install/` and `log/` in Docker volumes, so you only build the packages once, not on every start;
- names the container `slam_deployment`.

| Option / variable | Effect |
|---|---|
| `--gpu` | pass the NVIDIA GPU through (needs the NVIDIA Container Toolkit) |
| `BAG_DIR=/path/to/bags` | mount a different host bag folder at `/root/bags` |
| `ROS_DOMAIN_ID=<n>` | forwarded into the container if set on the host |

```bash
# example: GPU on, bags from an external drive
BAG_DIR=/media/$USER/data/rosbags ./slam_deployment/start.sh --gpu
```

The container is removed when you exit this first terminal (`--rm`); the built packages stay in the Docker volumes.

### Opening more terminals

Most steps below need several terminals (sensors or rosbag in one, SLAM in another, RViz in a third). Open each extra terminal on the **host** and run:

```bash
./slam_deployment/attach.sh
```

This runs `docker exec -it slam_deployment bash`. Every container shell already sources ROS 2 and, once it is built, the workspace (`/root/ws/install/setup.bash`). Running `start.sh` again while the container is up does the same thing.

### Alternative: VS Code Dev Container

The repository also ships a Dev Container definition under `slam_deployment/.devcontainer/`.

1. Install the **Dev Containers** extension in VS Code.
2. Open the `slam_deployment` folder in VS Code.
3. Run **Dev Containers: Reopen in Container** from the command palette.

>VS Code builds the image, mounts the workspace at `/root/ws/src` and `~/rosbags` at `/root/bags`, and runs the initial `colcon build` automatically via the container's `postCreateCommand`.

---
## 4. Build the SLAM packages

Inside the container, build the whole workspace once:

```bash
cd /root/ws
colcon build --symlink-install
source install/setup.bash
```

To (re)build just one package after editing it, use `--packages-select`, then re-source:

```bash
colcon build --symlink-install --packages-select fast_limo
source /root/ws/install/setup.bash
```

> Terminals opened **after** a build source the workspace automatically. Terminals that were already open need `source /root/ws/install/setup.bash`.

---
## 5. Launch the sensors

Every SLAM package needs LiDAR and/or camera data plus IMU data. Either bring up the real sensors, or play the tutorial rosbag.

### Option A: Live sensors

Start your sensor drivers, on the host or inside the container, so they publish the LiDAR, IMU and camera topics. Then check from a container terminal that the data arrives:

```bash
ros2 topic list
ros2 topic hz /ouster/points
```

Each SLAM package subscribes to fixed topic names from its config file (see [Run a SLAM package](#6-run-a-slam-package)); edit those to match your sensors.

### Option B: Play a rosbag

**Download the rosbag here:** [Example Rosbags](https://saxion.data.surf.nl/s/TiMtHpmo25H24LT)

The container plays both rosbag formats, **SQLite** (`.db3`) and **MCAP** (`.mcap`); `ros2 bag play` detects the format from the bag's `metadata.yaml`.

1. Unpack the downloaded bag folder into `~/rosbags` on the **host** (or the folder you pass as `BAG_DIR` to `start.sh`). It then appears inside the container under `/root/bags/<bag_folder>`.

2. Start the SLAM package first (see [Run a SLAM package](#6-run-a-slam-package)).

3. In another container terminal (`./slam_deployment/attach.sh`), go into the bag folder and play it (<kbd>Tab</kbd> completes the long folder name):

   ```bash
   cd /root/bags/<bag_folder>
   ros2 bag play . --clock --qos-profile-overrides-path qos/play_overrides.yaml
   ```

   `.` is the bag folder itself (the one with `metadata.yaml`), so the same command works for `.db3` and `.mcap` bags. Keep `--clock`: the SLAM nodes run on the bag's time (`use_sim_time`).

> **Note:** always launch the SLAM algorithm **first** and start the bag **after** it, otherwise the algorithm misses the start of the recording, which it needs to initialise.

> If you see `Ignoring a topic '/ublox_rover_node/navpvt', reason: package 'ublox_msgs' not found`, your image predates the GNSS message packages (`ublox_msgs`, `nmea_msgs`, `rtcm_msgs`). Rebuild it with `./slam_deployment/build_docker.sh` and restart the container.

> The tutorial bag was recorded with the Zenoh middleware. Its `qos/play_overrides.yaml` file makes the played topics visible to normal ROS 2 nodes; without it only `/tf` shows up. For a bag without that file, drop the `--qos-profile-overrides-path` option.

### Zenoh-recorded rosbags (rmw_zenoh)

Instead of the QoS override file, you can play the bag on the same middleware it was recorded with. Then **every** ROS 2 process (the SLAM node, RViz and `ros2 bag play`) must use Zenoh and talk through a running Zenoh router.

In **every** container terminal, select the Zenoh middleware:

```bash
export RMW_IMPLEMENTATION=rmw_zenoh_cpp
```

In **one** of those terminals, start the Zenoh router and leave it running:

```bash
ros2 run rmw_zenoh_cpp rmw_zenohd
```

Then, in the other terminals, start the SLAM package and play the bag (without the override file) as usual.

> `RMW_IMPLEMENTATION` only affects the shell it is exported in, so set it in **every** terminal. Mixing a Zenoh terminal with a Fast DDS terminal does not work: they cannot see each other.

---

## 6. Run a SLAM package

All commands below run **inside the container**, with the workspace built (step 4). Use one terminal for the SLAM package and another for the sensors or the rosbag (step 5). Start the SLAM package **first**, then the data, so the beginning of the recording isn't missed.

### Fast-LIMO

> **Upstream project:** [fetty31/fast_LIMO](https://github.com/fetty31/fast_LIMO) algorithm details, full parameter reference and datasets.

Package `fast_limo`. The default config `fast_LIMO/config/params.yaml` already matches the tutorial rosbag: it subscribes to `/ouster/points` and `/ouster/imu` with `sensor_type: 0` (Ouster).

```bash
# terminal 1 : the SLAM node (+ RViz)
ros2 launch fast_limo fast_limo.launch.py rviz:=True

# terminal 2 : the rosbag (LiDAR + IMU are all Fast-LIMO needs)
cd /root/bags/<bag_folder>
ros2 bag play . --clock --qos-profile-overrides-path qos/play_overrides.yaml \
  --topics /ouster/points /ouster/imu
```

> **Calibration:** Fast-LIMO estimates the IMU biases and gravity during the first 3 s (`calibration.time`), so the sensor must stand still at the start of the data. For other sensors, set `topics.input`, `sensor_type` and the LiDAR/IMU `extrinsics` in `params.yaml`, then rebuild (`colcon build --symlink-install --packages-select fast_limo`).

### FAST-LIO

> **Upstream project:** [hku-mars/FAST_LIO](https://github.com/hku-mars/FAST_LIO) algorithm details, full parameter reference and datasets.

Package `fast_lio`. Sensor configs live in `FAST_LIO_ROS2/config/` : `avia.yaml`, `horizon.yaml`, `mid360.yaml`, `ouster64.yaml`, `ouster128.yaml`, `velodyne.yaml`. Pick the one for your LiDAR and edit its `lid_topic` / `imu_topic` to match your data.

```bash
# live : subscribe to a running sensor or an externally played bag (RViz on by default)
ros2 launch fast_lio mapping_rviz.launch.py config_file:=ouster64.yaml

# bag : launch the node and play a bag together
ros2 launch fast_lio mapping_bag.launch.py \
  bag_folder:=/root/bags/<your_bag> \
  config_file:=ouster64.yaml \
  use_sim_time:=true
```

> `config_file` defaults to `ouster128.yaml`; `rviz:=false` disables the RViz window.

### LeGO-LOAM

> **Upstream project:** [RobustFieldAutonomyLab/LeGO-LOAM](https://github.com/RobustFieldAutonomyLab/LeGO-LOAM) algorithm details and the original paper.

Package `lego_loam_sr`. The launch file sets up the required TF tree, opens RViz, and **plays the bag itself**, so `bag_folder` is mandatory. Its input point cloud is remapped from `/rslidar_points` to `/ouster/points` (edit the `remappings` in `run.launch.py` for a different topic).

```bash
ros2 launch lego_loam_sr run.launch.py bag_folder:=/root/bags/<your_bag>
```

> `config_file` defaults to `loam_config_corridor.yaml` (also available: `loam_config.yaml`), override with `config_file:=<path>`. Play **only** the LiDAR topic from your bag, replaying the bag's `/tf` interferes with LeGO-LOAM's own transforms.

### VINS-Fusion

> **Upstream project:** [HKUST-Aerial-Robotics/VINS-Fusion](https://github.com/HKUST-Aerial-Robotics/VINS-Fusion) algorithm details, supported sensors and datasets.

Packages `vins`, `loop_fusion`, `global_fusion`, `camera_models`. Camera/IMU configs live in `VINS-Fusion-ROS2/config/` (e.g. `euroc/`, `kitti_odom/`, `kitti_raw/`, `realsense_d435i/`, `mynteye/`). Both launch files take a `config:=` (full path to the config YAML) and a `bag_folder:=` argument, and play the bag themselves.

```bash
# VIO + RViz
ros2 launch vins vins_rviz.launch.py \
  config:=/root/ws/src/VINS-Fusion-ROS2/config/euroc/euroc_stereo_imu_config.yaml \
  bag_folder:=/root/bags/<your_bag>

# VIO + loop closure (adds the loop_fusion node) + RViz
ros2 launch vins vins_lc_rviz.launch.py \
  config:=/root/ws/src/VINS-Fusion-ROS2/config/euroc/euroc_stereo_imu_config.yaml \
  bag_folder:=/root/bags/<your_bag>
```

> To run the estimator by itself without a bag, use the node directly : `ros2 run vins vins_node <path_to_config.yaml>`. GPU acceleration can be toggled inside the chosen config file.

---

## Troubleshooting

- **`packages not found` :** The workspace has not been built or sourced. Run `colcon build --symlink-install` in `/root/ws`, then `source /root/ws/install/setup.bash`.

- **Empty submodule folders :** The submodules were not initialised on the host. Run `git submodule update --init --recursive` in the repository root and restart the container.

- **Only `/tf` appears while the bag plays :** The bag was played without `--qos-profile-overrides-path qos/play_overrides.yaml`. See [Option B: Play a rosbag](#option-b-play-a-rosbag).

- **`can't open '/qos/play_overrides.yaml'` :** The path starts with `/` (or uses an unset variable such as `$BAG`), so it points to the container root. Run the command from inside the bag folder with the relative path `qos/play_overrides.yaml`.

- **`ros2 topic list` is empty / nodes don't discover each other :** First restart the discovery daemon, which caches results and can go stale after a network change: `ros2 daemon stop` (it restarts on the next command). Then confirm `ROS_DOMAIN_ID` and `RMW_IMPLEMENTATION` match in every terminal and the container runs with `--net=host`. Do **not** add `--hostname` to the `docker run` command: with `--net=host` the custom hostname is missing from `/etc/hosts`, which breaks discovery.

- **RViz / GUI window does not appear :** Run `xhost +local:` on the host (`start.sh` does this) and make sure `DISPLAY` is forwarded.

- **Start from a clean build / `rm: cannot remove 'build': Device or resource busy` :** `build/`, `install/` and `log/` are Docker volumes mounted by `start.sh`, so the folders themselves can't be deleted from inside the container. Delete their **contents** instead, then rebuild:

  ```bash
  cd /root/ws && rm -rf build/* install/* log/*
  colcon build --symlink-install
  ```
