# ROS 2 Humble + VINS-Fusion-ROS2 + Ceres
FROM osrf/ros:humble-desktop

ENV DEBIAN_FRONTEND=noninteractive

SHELL ["/bin/bash", "-c"]

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


# RUN mkdir -p /root/vins_ws/src
# WORKDIR /root/vins_ws/src
# RUN git clone https://github.com/SaxionMechatronics/VINS-Fusion-ROS2

# WORKDIR /root/vins_ws
# RUN source /opt/ros/humble/setup.bash && \
#     colcon build --symlink-install

RUN echo "source /opt/ros/humble/setup.bash" >> /root/.bashrc 

CMD ["bash"]
