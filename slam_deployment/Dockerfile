FROM osrf/ros:humble-desktop

ENV DEBIAN_FRONTEND=noninteractive

SHELL ["/bin/bash", "-c"]

## Setting up for vins
RUN apt-get update && apt-get install -y \
    build-essential \
    cmake \
    libgoogle-glog-dev \
    libatlas-base-dev \
    libsuitesparse-dev \
    libeigen3-dev \
    wget \
    git \
    python3-colcon-common-extensions \
    python3-rosdep \
    python3-vcstool \
 && rm -rf /var/lib/apt/lists/*


RUN rosdep init || echo "rosdep already initialized" && \
    rosdep update || echo "rosdep update failed (maybe no network)"


WORKDIR /root
RUN mkdir -p /root/sources


WORKDIR /root/sources
RUN wget http://ceres-solver.org/ceres-solver-2.1.0.tar.gz && \
    tar zxf ceres-solver-2.1.0.tar.gz && \
    mkdir -p ceres-solver-2.1.0/build && \
    cd ceres-solver-2.1.0/build && \
    cmake .. && \
    make -j"$(nproc)" && \
    make install && \
    rm /root/sources/ceres-solver-2.1.0.tar.gz


RUN echo "source /opt/ros/humble/setup.bash" >> /root/.bashrc 


## Setting up for fastlio
RUN apt-get update && apt-get install -y --no-install-recommends ros-humble-pcl-ros; 

RUN mkdir -p /root/sources/ros_ws/src
WORKDIR /root/sources/ros_ws/src
RUN git clone https://github.com/Ericsii/livox_ros_driver2.git
WORKDIR /root/sources/ros_ws
RUN source /opt/ros/humble/setup.bash && \
    colcon build --symlink-install

RUN echo "source /root/sources/ros_ws/install/setup.bash" >> /root/.bashrc 

## Setting up for lego-loam
RUN apt-get install -y --no-install-recommends unzip; 
WORKDIR /root/sources
RUN wget -O gtsam.zip https://github.com/borglab/gtsam/archive/refs/tags/4.1.1.zip && \
    unzip gtsam.zip && \
    rm -rf gtsam.zip 
RUN mkdir -p gtsam-4.1.1/build && \
    cd gtsam-4.1.1/build && \
    cmake -DGTSAM_USE_SYSTEM_EIGEN=ON .. && \
    make -j"$(nproc)" && \
    make install && \
    echo "/usr/local/lib" > /etc/ld.so.conf.d/local.conf && \
    ldconfig


## Setting up for fast_LIMO
# Header-only IKFoM + Eigen3 (already installed above); PCL >= 1.12 and the ROS
# message/tf packages the wrapper links against are pulled in explicitly here.
RUN apt-get update && apt-get install -y --no-install-recommends \
    libpcl-dev \
    ros-humble-pcl-conversions \
    ros-humble-tf2 \
    ros-humble-tf2-ros \
    ros-humble-nav-msgs \
    ros-humble-visualization-msgs \
 && rm -rf /var/lib/apt/lists/*


## Setting up for EVO
COPY requirements.txt .
RUN apt-get update && apt-get install -y --no-install-recommends python3-pip \
 && rm -rf /var/lib/apt/lists/*
RUN pip install --no-cache-dir --upgrade pip && \
    pip install --no-cache-dir -r requirements.txt
RUN evo_config set plot_backend Agg

CMD ["bash"]
