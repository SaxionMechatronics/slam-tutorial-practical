## Preliminary
Install docker and docker compose v2.
On ub20/22:
```
# 1. Update and install prerequisites
sudo apt update
sudo apt install -y ca-certificates curl gnupg lsb-release

# 2. Add Docker’s official GPG key
sudo mkdir -p /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | \
  sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg

# 3. Set up the Docker repository
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] \
  https://download.docker.com/linux/ubuntu \
  $(lsb_release -cs) stable" | \
  sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
# 4. Verify the installation 
sudo docker run hello-world

# 4. Install Docker Engine and Docker Compose V2
sudo apt update
sudo apt install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
```

```
sudo groupadd docker
sudo usermod -aG docker $USER
newgrp docker
```

## Build docker images for 
after installing docker then clone the repository with all submodules (only if you haven't cloned it yet)
```
git --recurse-submodules clone git@github.com:eliyaskidnae/slam-tutorial-practical.git

```

## Build camera callibration 
```
cd slam-tutorial-practical/camera_callibration_ws
docker compose exec callibration bash --login
source /opt/ros/humble/setup.bash
colcon build 
```
