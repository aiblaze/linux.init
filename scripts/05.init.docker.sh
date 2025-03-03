#!/bin/bash

# Source helper functions
source ./scripts/utils/helpers.sh

log_section "Docker Installation and Configuration"

# Check if running as root
check_root

log "Starting Docker installation for AlmaLinux..."

# Step 1: Configure Docker mirror repository
log "Configuring Docker repository..."
execute "dnf -y install dnf-utils" "Failed to install dnf-utils" "dnf-utils installed successfully"
execute "dnf config-manager --add-repo https://mirrors.aliyun.com/docker-ce/linux/centos/docker-ce.repo" "Failed to add Docker repository" "Docker repository configured successfully"

# Step 2: Install Docker
log "Installing Docker packages..."
execute "dnf -y install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin" "Docker installation failed" "Docker installed successfully"

# Step 3: Configure Docker image acceleration
log "Configuring Docker image acceleration..."
execute "mkdir -p /etc/docker" "Failed to create Docker configuration directory" "Docker configuration directory created"

# Create Docker daemon configuration file with registry mirror
log "Setting up Docker daemon configuration..."

# Check for environment variable, then command line argument, then use default
DEFAULT_MIRROR="https://n3zlurtb.mirror.aliyuncs.com"
REGISTRY_MIRROR=${DOCKER_REGISTRY_MIRROR:-${1:-$DEFAULT_MIRROR}}

log "Detected registry mirror: $REGISTRY_MIRROR"

# Ask if user wants to use a different registry mirror
if confirm_action "Do you want to use the current registry mirror ($REGISTRY_MIRROR)?"; then
  log "Using registry mirror: $REGISTRY_MIRROR"
else
  read -p "Enter your preferred Docker registry mirror URL: " custom_mirror
  if [ -n "$custom_mirror" ]; then
    REGISTRY_MIRROR="$custom_mirror"
    log "Using custom registry mirror: $REGISTRY_MIRROR"
  else
    log_warning "No mirror provided, using default: $REGISTRY_MIRROR"
  fi
fi

# Create the daemon.json file
cat > /etc/docker/daemon.json <<EOF
{
  "registry-mirrors": ["$REGISTRY_MIRROR"],
  "log-driver": "json-file",
  "log-opts": {
    "max-size": "100m",
    "max-file": "3"
  },
  "storage-driver": "overlay2"
}
EOF

if [ $? -ne 0 ]; then
  log_error "Failed to create Docker daemon configuration file"
  exit 1
fi
log "Docker daemon configuration file created successfully"

# Step 4: Start Docker and enable on boot
log "Starting Docker service..."
execute "systemctl enable docker" "Failed to enable Docker service" "Docker service enabled successfully"
execute "systemctl start docker" "Failed to start Docker service" "Docker service started successfully"

# Step 5: Verify Docker installation
log "Verifying Docker installation..."
if command_exists "docker"; then
  docker_version=$(docker --version)
  log "Docker version: $docker_version"
else
  log_error "Docker command not found. Installation may have failed."
  exit 1
fi

# Run hello-world container to verify Docker functionality
log "Running test container to verify Docker functionality..."
if execute "docker run --rm hello-world" "Docker test container failed" "Docker test container ran successfully"; then
  :  # No-op, continue
else
  log_warning "Docker may not be functioning properly. You might need to restart the system."
fi

# Display Docker info
log "Docker installation details:"
execute "docker version --format '{{.Server.Version}}'" "Failed to get Docker version" "Docker Server version"

# Display registry mirrors
log "Docker registry mirrors configuration:"
if execute "docker info | grep 'Registry Mirrors' -A 3" "Failed to get mirror information" ""; then
  :  # No-op, continue
else
  log_warning "Could not verify registry mirrors configuration."
  log "Current daemon.json content:"
  cat /etc/docker/daemon.json
fi

log "Docker post-installation steps:"
log "1. To use Docker without sudo, add your user to the docker group:"
log "   sudo usermod -aG docker your-user"
log "2. Log out and log back in to apply the changes"
log "3. Test with: docker run hello-world"

log "Docker installation and configuration completed successfully."
