#/usr/bin/env bash

# Combined Script, Replace v2.18.1 with latest available compose version
sudo apt update
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
sudo add-apt-repository "deb [arch=arm64] https://download.docker.com/linux/ubuntu focal stable"
sudo apt install -y apt-transport-https ca-certificates curl software-properties-common
sudo apt install -y docker-ce

sudo curl -L "https://github.com/docker/compose/releases/download/v2.18.1/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose
docker-compose --version

sudo systemctl status docker

sudo apt update

curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
sudo add-apt-repository "deb [arch=arm64] https://download.docker.com/linux/ubuntu focal stable"

sudo apt install -y apt-transport-https ca-certificates curl software-properties-common

# allow the current user to use docker as if they were root
sudo usermod -aG docker $USER