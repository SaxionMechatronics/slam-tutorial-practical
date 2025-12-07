FROM ubuntu:20.04 AS base20
RUN apt-get update && apt-get install -y curl gnupg2 lsb-release

# No interactive prompts (e.g. in apt and correct timezone)
ENV DEBIAN_FRONTEND=noninteractive
ENV TZ=Etc/UTC
SHELL ["/bin/bash", "-c"]

ARG USERNAME=rosuser

# Create a non-root user matching host UID/GID
ARG USERNAME=rosuser
ARG USER_UID=1000
ARG USER_GID=1000

RUN groupadd -g $USER_GID $USERNAME \
    && useradd -m -u $USER_UID -g $USER_GID -s /bin/bash $USERNAME \
    && apt-get update \
    && apt-get install -y sudo \
    && echo "$USERNAME ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers


# Add the ROS GPG key safely (modern approach)
RUN mkdir -p /usr/share/keyrings
RUN curl -fsSL https://raw.githubusercontent.com/ros/rosdistro/master/ros.asc | \
    gpg --dearmor -o /usr/share/keyrings/ros-archive-keyring.gpg

# Add the ROS repository with proper keyring reference
RUN echo "deb [signed-by=/usr/share/keyrings/ros-archive-keyring.gpg] http://packages.ros.org/ros/ubuntu $(lsb_release -sc) main" \
    > /etc/apt/sources.list.d/ros-latest.list


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

RUN echo "source /opt/ros/noetic/setup.bash" >> /home/$USERNAME/.bashrc

# Setup ROS2 workspace
ENV ROS_WS=/home/$USERNAME/callibration_ros1_ws
RUN mkdir -p $ROS_WS/src
WORKDIR $ROS_WS
