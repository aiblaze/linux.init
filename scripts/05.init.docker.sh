#!/bin/bash

# Source helper functions
source ./scripts/utils/helpers.sh

log_section "Docker Installation and Configuration"

# Check if running as root
check_root

# Set default values for configuration variables
DEFAULT_MIRROR="https://n3zlurtb.mirror.aliyuncs.com"
DOCKER_REGISTRY_MIRROR=${DOCKER_REGISTRY_MIRROR:-$DEFAULT_MIRROR}
DOCKER_LOG_MAX_SIZE=${DOCKER_LOG_MAX_SIZE:-"100m"}
DOCKER_LOG_MAX_FILE=${DOCKER_LOG_MAX_FILE:-"3"}
DOCKER_STORAGE_DRIVER=${DOCKER_STORAGE_DRIVER:-"overlay2"}

# Log configuration
log "Using Docker configuration:"
log "Registry Mirror: $DOCKER_REGISTRY_MIRROR"
log "Log Max Size: $DOCKER_LOG_MAX_SIZE"
log "Log Max File: $DOCKER_LOG_MAX_FILE"
log "Storage Driver: $DOCKER_STORAGE_DRIVER"

log "Starting Docker installation for $OS_PRETTY_NAME..."

# Step 1: Configure Docker repository based on OS family
log "Configuring Docker repository..."

case "$OS_FAMILY" in
  "debian")
    # Install prerequisites
    execute "$PKG_INSTALL apt-transport-https ca-certificates curl gnupg lsb-release" \
      "Failed to install prerequisites" \
      "Prerequisites installed successfully"
    
    # Add Docker's official GPG key
    execute "curl -fsSL https://download.docker.com/linux/$OS_NAME/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg" \
      "Failed to add Docker GPG key" \
      "Docker GPG key added successfully"
    
    # Set up the stable repository
    execute "echo \"deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/$OS_NAME $(lsb_release -cs) stable\" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null" \
      "Failed to add Docker repository" \
      "Docker repository added successfully"
    
    # Update apt package index
    execute "$PKG_UPDATE" \
      "Failed to update package index" \
      "Package index updated successfully"
    ;;
    
  "rhel")
    # Install prerequisites
    execute "$PKG_INSTALL dnf-utils" \
      "Failed to install dnf-utils" \
      "dnf-utils installed successfully"
    
    # Add Docker repository
    execute "$PKG_MANAGER config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo" \
      "Failed to add Docker repository" \
      "Docker repository configured successfully"
    ;;
    
  *)
    log_error "Unsupported OS family: $OS_FAMILY"
    exit 1
    ;;
esac

# Step 2: Install Docker
log "Installing Docker packages..."
execute "$PKG_INSTALL docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin" \
  "Docker installation failed" \
  "Docker installed successfully"

# Step 3: Configure Docker image acceleration
log "Configuring Docker image acceleration..."
execute "mkdir -p /etc/docker" \
  "Failed to create Docker configuration directory" \
  "Docker configuration directory created"

# Create Docker daemon configuration file with registry mirror
log "Setting up Docker daemon configuration..."

log "Detected registry mirror: $DOCKER_REGISTRY_MIRROR"

# In non-interactive mode, use the provided registry mirror without prompting
# Otherwise, ask if user wants to use a different registry mirror
if [ "$NON_INTERACTIVE" = "true" ] || confirm_action "Do you want to use the current registry mirror ($DOCKER_REGISTRY_MIRROR)?"; then
  log "Using registry mirror: $DOCKER_REGISTRY_MIRROR"
else
  read -p "Enter your preferred Docker registry mirror URL: " custom_mirror
  if [ -n "$custom_mirror" ]; then
    DOCKER_REGISTRY_MIRROR="$custom_mirror"
    log "Using custom registry mirror: $DOCKER_REGISTRY_MIRROR"
  else
    log_warning "No mirror provided, using default: $DOCKER_REGISTRY_MIRROR"
  fi
fi

# Create the daemon.json file
cat > /etc/docker/daemon.json <<EOF
{
  "registry-mirrors": ["$DOCKER_REGISTRY_MIRROR"],
  "log-driver": "json-file",
  "log-opts": {
    "max-size": "$DOCKER_LOG_MAX_SIZE",
    "max-file": "$DOCKER_LOG_MAX_FILE"
  },
  "storage-driver": "$DOCKER_STORAGE_DRIVER"
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
