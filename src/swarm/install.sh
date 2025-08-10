#!/usr/bin/env bash

# ===============
# INSTALL DOCKER 
# ===============
export DEBIAN_FRONTEND=noninteractive
if docker --version; then 
  echo "docker is already installed"
  exit 0
fi

sudo apt-get update -y -qq
sudo apt-get install -y \
                ca-certificates \
                curl \
                gnupg \
                apt-transport-https \
                gnupg-agent \
                software-properties-common
 
sudo install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
echo \
      "deb [arch="$(dpkg --print-architecture)" signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
      "$(. /etc/os-release && echo "$VERSION_CODENAME")" stable" | \
      sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

echo "update 2"
sudo apt-get update -y -qq
sudo apt-get install -y -qq docker-ce \
                docker-ce-cli \
                containerd.io \
                docker-buildx-plugin \
                docker-compose-plugin
# sudo usermod -aG docker $USER
# sudo reboot  # Refresh group permissions

if docker --version; then 
    echo "✅ Docker installed!"
else
    echo "❌ Docker installation failed!"
    exit 1
fi
