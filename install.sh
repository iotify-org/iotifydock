#!/bin/bash
# ------------------------------------------------------------------
# [Author] Title
#          Description
# ------------------------------------------------------------------

cd /

apt-get update
apt dist-upgrade -y
apt install fail2ban -y

#DOCKER
apt-get install -y \
    apt-transport-https \
    ca-certificates \
    curl \
    gnupg-agent \
    software-properties-common
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
apt-key fingerprint 0EBFCD88
apt-get update
apt-get install docker-ce docker-ce-cli containerd.io -y
docker run hello-world


#DOCKER COMPOSE
curl -L "https://github.com/docker/compose/releases/download/1.25.4/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-$
chmod +x /usr/local/bin/docker-compose
docker-compose --version

#IOTIFY
git clone https://github.com/iotify-org/iotifydock.git


