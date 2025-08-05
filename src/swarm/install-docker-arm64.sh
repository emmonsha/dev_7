#!/bin/bash

sudo apt-get install -y \
	       apt-transport-https \
	       ca-certificates \
	       curl \
	       gnupg2 \
	       software-properties-common

curl -fsSL https://download.docker.com/linux/debian/gpg | sudo apt-key add -

echo "deb [arch=arm64] https://download.docker.com/linux/debian $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list

sudo apt-get update
sudo apt-get upgrade -y
sudo apt-get install -y docker-ce

# allow the current user to use docker as if they were root
sudo usermod -aG docker $USER

# setup plain http access to a LAN docker registry
sudo tee /etc/docker/daemon.json <<EOF
{
  "insecure-registries": ["rock64-01.local:5000","10.0.1.5:5000"]
}
EOF