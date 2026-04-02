#!/bin/bash
set -euo pipefail

# Redirect both stdout and stderr to a file
exec >output.txt 2>&1

# No interactive input at all
export DEBIAN_FRONTEND=noninteractive

# Mount minecraft data disk
mkdir -p /mnt/disks/aria-data-disk
mount -o discard,defaults /dev/disk/by-id/google-aria-data-disk /mnt/disks/aria-data-disk

# Create scripts for server
mkdir -p /opt/scripts
gsutil -m cp -r gs://aria-minecraft-server/scripts/* /opt/scripts/

# Synchronize mods (uncomment if needed)
# gsutil -m rsync -d gs://aria-minecraft-server/mods /mnt/disks/aria-data-disk/mods

# Upgrade system packages
apt-get update
apt-get upgrade -y

# Install general packages
apt-get install -y git bc

# Install Ops Agent
curl -sSO https://dl.google.com/cloudagents/add-google-cloud-ops-agent-repo.sh
bash add-google-cloud-ops-agent-repo.sh --also-install
rm add-google-cloud-ops-agent-repo.sh

# Add Docker's official GPG key
apt-get update
apt-get install -y ca-certificates curl
install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/debian/gpg -o /etc/apt/keyrings/docker.asc
chmod a+r /etc/apt/keyrings/docker.asc

# Add the repository to Apt sources
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/debian \
  $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
  tee /etc/apt/sources.list.d/docker.list > /dev/null
apt-get update

# Install docker packages
apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

# Run Minecraft docker image with health check
docker run --privileged -d -v /mnt/disks/aria-data-disk/:/data \
    -e TYPE=FABRIC -e MEMORY=28G -e DEBUG=true -e PVP=false \
    -e ENABLE_AUTOSTOP=TRUE -e AUTOSTOP_TIMEOUT_EST=350 \
    -e AUTOSTOP_TIMEOUT_INIT=600 -e ONLINE_MODE=false \
    -e VERSION=1.20.1 \
    -p 25565:25565 -e EULA=TRUE --name mc \
    itzg/minecraft-server:java17

# Wait for Minecraft server to start
echo "Waiting for Minecraft server to start..."
sleep 45s
echo "Minecraft server should be ready!"

# Call the scripts downloaded from GCS
bash /opt/scripts/send_ip_address.sh
bash /opt/scripts/auto_destroy.sh
