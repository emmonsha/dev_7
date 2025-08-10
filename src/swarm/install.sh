#!/usr/bin/env bash

    sudo apt update
    # Install necessary packages for adding a repository over HTTPS:
  
    sudo apt install ca-certificates curl gnupg lsb-release
    
    # Add Docker's GPG key.
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
    
    # Add the Docker repository.
    echo "deb [arch=arm64 signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
   
    # Update package lists again to include the new repository:
    sudo apt update


    # Install Docker Engine, CLI, and containerd:
    sudo apt install docker-ce docker-ce-cli containerd.io

    # Add your user to the docker group to run Docker commands without sudo: 
    sudo usermod -aG docker $USER
