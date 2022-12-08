#!/bin/sh

#Parameters
#$1 - domain

#wait until another process are trying updating the system
while sudo fuser /var/{lib/{dpkg,apt/lists},cache/apt/archives}/lock >/dev/null 2>&1; do sleep 1; done
while sudo fuser /var/lib/dpkg/lock-frontend >/dev/null 2>&1; do sleep 1; done

#Open only necessary ports
sudo ufw allow 80
sudo ufw allow 443
sudo ufw allow 22
sudo ufw allow 9418
sudo ufw --force enable

#Install Podman
DEBIAN_FRONTEND=noninteractive  sudo apt-get update
DEBIAN_FRONTEND=noninteractive  sudo apt-get -y install podman

#Install npm & node.js
DEBIAN_FRONTEND=noninteractive  sudo apt-get -y install npm

#Install PM2
npm install pm2@latest -g

#Generate SSH keys
ssh-keygen

ssh-keyscan bitbucket.org >> ~/.ssh/known_hosts
ssh-keyscan github.com >> ~/.ssh/known_hosts

#Install Caddy Server
DEBIAN_FRONTEND=noninteractive sudo apt install -y debian-keyring debian-archive-keyring apt-transport-https
curl -1sLf 'https://dl.cloudsmith.io/public/caddy/stable/gpg.key' | sudo gpg --batch --yes --dearmor -o /usr/share/keyrings/caddy-stable-archive-keyring.gpg
curl -1sLf 'https://dl.cloudsmith.io/public/caddy/stable/debian.deb.txt' | sudo tee /etc/apt/sources.list.d/caddy-stable.list
sudo apt update
DEBIAN_FRONTEND=noninteractive sudo apt -y install caddy

#Install Deployed.cc service-node
git clone https://coded-sh@bitbucket.org/coded-sh/service-node.git
cd service-node
npm install
SERVICE_NODE_DOMAIN=$1  pm2 start index.js --name service-node 
pm2 startup
pm2 save

#Reboot (optional)
#reboot