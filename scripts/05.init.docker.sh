#!/bin/bash

# AlmaLinux Docker Installation Script
# 1. Configure Alibaba Cloud Docker repository
# 2. Install Docker
# 3. Configure Docker image acceleration
# 4. Start and verify Docker installation

# Set colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
NC='\033[0m' # No Color

# Check if script is run as root
if [ "$(id -u)" -ne 0 ]; then
    echo -e "${RED}This script must be run as root${NC}" >&2
    exit 1
fi

echo -e "${YELLOW}Starting Docker installation for AlmaLinux...${NC}"

# Step 1: Configure Alibaba Cloud Docker mirror repository
echo -e "${YELLOW}Step 1: Configuring Alibaba Cloud Docker repository...${NC}"
dnf -y install dnf-utils
dnf config-manager --add-repo https://mirrors.aliyun.com/docker-ce/linux/centos/docker-ce.repo

if [ $? -ne 0 ]; then
    echo -e "${RED}Failed to add Docker repository.${NC}" >&2
    exit 1
fi
echo -e "${GREEN}Docker repository configured successfully.${NC}"

# Step 2: Install Docker
echo -e "${YELLOW}Step 2: Installing Docker...${NC}"
dnf -y install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

if [ $? -ne 0 ]; then
    echo -e "${RED}Docker installation failed.${NC}" >&2
    exit 1
fi
echo -e "${GREEN}Docker installed successfully.${NC}"

# Step 3: Configure Docker image acceleration
echo -e "${YELLOW}Step 3: Configuring Docker image acceleration...${NC}"
mkdir -p /etc/docker
cat > /etc/docker/daemon.json <<EOF
{
  "registry-mirrors": ["https://n3zlurtb.mirror.aliyuncs.com"],
  "log-driver": "json-file",
  "log-opts": {
    "max-size": "100m",
    "max-file": "3"
  },
  "storage-driver": "overlay2"
}
EOF

echo -e "${GREEN}Docker image acceleration configured.${NC}"

# Step 4: Start Docker and enable on boot
echo -e "${YELLOW}Step 4: Starting Docker service...${NC}"
systemctl enable docker
systemctl start docker

if [ $? -ne 0 ]; then
    echo -e "${RED}Failed to start Docker service.${NC}" >&2
    exit 1
fi
echo -e "${GREEN}Docker service started successfully.${NC}"

# Step 5: Verify Docker installation
echo -e "${YELLOW}Step 5: Verifying Docker installation...${NC}"
docker --version
docker run hello-world

if [ $? -ne 0 ]; then
    echo -e "${RED}Docker verification failed. Please check your installation.${NC}" >&2
    exit 1
fi

# Display Docker info
echo -e "${GREEN}Docker has been successfully installed and verified!${NC}"
echo -e "${YELLOW}Docker Version:${NC}"
docker version

echo -e "${YELLOW}Docker Info:${NC}"
docker info | grep "Registry Mirrors" -A 3

echo -e "${GREEN}Docker installation completed successfully.${NC}"