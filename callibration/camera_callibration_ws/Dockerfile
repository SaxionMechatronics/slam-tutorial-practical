# ubuntu 22 + ROS2 Humble + ZED SDK 5.0 for Jetson
FROM ubuntu:22.04

ENV DEBIAN_FRONTEND=noninteractive
ENV TZ=Etc/UTC
SHELL ["/bin/bash", "-c"]

# Create a non-root user matching host UID/GID
ARG USERNAME=rosuser
ARG USER_UID=1000
ARG USER_GID=1000

RUN groupadd -g $USER_GID $USERNAME \
    && useradd -m -u $USER_UID -g $USER_GID -s /bin/bash $USERNAME \
    && apt-get update \
    && apt-get install -y sudo \
    && echo "$USERNAME ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers

#Install base tools required for ROS 2 repo setup
RUN apt-get update && apt-get install -y \
    software-properties-common \
    curl \
    lsb-release \
    gnupg2

# Add ROS 2 source (based on Ubuntu release)
RUN export UBUNTU_CODENAME=$(. /etc/os-release && echo ${UBUNTU_CODENAME:-${VERSION_CODENAME}}) && \
    export ROS_APT_SOURCE_VERSION=$(curl -s https://api.github.com/repos/ros-infrastructure/ros-apt-source/releases/latest | grep -F "tag_name" | awk -F\" '{print $4}') && \
    curl -L -o /tmp/ros2-apt-source.deb "https://github.com/ros-infrastructure/ros-apt-source/releases/download/${ROS_APT_SOURCE_VERSION}/ros2-apt-source_${ROS_APT_SOURCE_VERSION}.${UBUNTU_CODENAME}_all.deb" && \
    dpkg -i /tmp/ros2-apt-source.deb && \
    rm -f /tmp/ros2-apt-source.deb


# Copy install script
COPY dependencies /tmp/dependencies
WORKDIR /tmp/dependencies

RUN chmod +x ./install.sh && ./install.sh

# Install git + bash-completion
RUN apt-get update && apt-get install -y \
    git \
    bash-completion \
    && rm -rf /var/lib/apt/lists/*

# Switch to non-root user
USER $USERNAME
WORKDIR /home/$USERNAME 

RUN echo "source /opt/ros/humble/setup.bash" >> /home/$USERNAME/.bashrc

# Setup ROS2 workspace
ENV ROS_WS=/home/$USERNAME/callibration_ws
RUN mkdir -p $ROS_WS/src
WORKDIR $ROS_WS