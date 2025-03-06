#!/bin/bash

#############################################################
# Docker 安装与配置脚本
# 
# 功能：
# - 安装 Docker 引擎及相关组件
# - 配置 Docker 镜像加速器（提高容器镜像拉取速度）
# - 配置 Docker 日志轮转和存储驱动
# - 支持 Debian/Ubuntu 和 RHEL/CentOS/AlmaLinux 系统
# - 默认使用阿里云镜像源（适合中国用户）
#
# 环境变量：
# - DOCKER_REGISTRY_ACCELERATOR: Docker 镜像加速器地址
# - DOCKER_LOG_MAX_SIZE: Docker 日志文件最大大小
# - DOCKER_LOG_MAX_FILE: Docker 日志文件保留数量
# - DOCKER_STORAGE_DRIVER: Docker 存储驱动
# - USE_OFFICIAL_DOCKER_REPO: 是否使用官方 Docker 软件包仓库
#############################################################

# Source helper functions
source ./scripts/utils/helpers.sh

log_section "Docker Installation and Configuration"

# Check if running as root
check_root

#############################################################
# Docker 配置涉及两种不同类型的"镜像"地址：
# 1. Docker Registry Accelerator (镜像加速器)：
#    - 用于加速从 Docker Hub 等公共镜像仓库拉取容器镜像
#    - 配置在 daemon.json 的 registry-mirrors 字段中
#    - 例如：https://n3zlurtb.mirror.aliyuncs.com
#
# 2. Docker Package Repository (软件包仓库)：
#    - 用于安装 Docker 引擎软件包本身
#    - 配置为系统的软件源
#    - 例如：https://mirrors.aliyun.com/docker-ce/linux/centos/docker-ce.repo
#############################################################

# Set default values for configuration variables
# Docker Registry Accelerator - 用于加速 Docker 镜像拉取
DEFAULT_REGISTRY_ACCELERATOR="https://n3zlurtb.mirror.aliyuncs.com"
DOCKER_REGISTRY_ACCELERATOR=${DOCKER_REGISTRY_ACCELERATOR:-$DEFAULT_REGISTRY_ACCELERATOR}
DOCKER_LOG_MAX_SIZE=${DOCKER_LOG_MAX_SIZE:-"100m"}
DOCKER_LOG_MAX_FILE=${DOCKER_LOG_MAX_FILE:-"3"}
DOCKER_STORAGE_DRIVER=${DOCKER_STORAGE_DRIVER:-"overlay2"}

# Set default Docker repository URLs (using Aliyun mirrors for China)
# Docker Package Repository - 用于安装 Docker 软件包的仓库地址
DEFAULT_DOCKER_REPO_DEBIAN="https://mirrors.aliyun.com/docker-ce/linux"
DEFAULT_DOCKER_REPO_RHEL="https://mirrors.aliyun.com/docker-ce/linux/centos/docker-ce.repo"
# Official Docker repositories
OFFICIAL_DOCKER_REPO_DEBIAN="https://download.docker.com/linux"
OFFICIAL_DOCKER_REPO_RHEL="https://download.docker.com/linux/centos/docker-ce.repo"
# Allow override through environment variables
# If USE_OFFICIAL_DOCKER_REPO is set to true, use official repositories
if [ "${USE_OFFICIAL_DOCKER_REPO:-false}" = "true" ]; then
  DOCKER_REPO_DEBIAN=${DOCKER_REPO_DEBIAN:-$OFFICIAL_DOCKER_REPO_DEBIAN}
  DOCKER_REPO_RHEL=${DOCKER_REPO_RHEL:-$OFFICIAL_DOCKER_REPO_RHEL}
  log "Using official Docker package repositories"
else
  DOCKER_REPO_DEBIAN=${DOCKER_REPO_DEBIAN:-$DEFAULT_DOCKER_REPO_DEBIAN}
  DOCKER_REPO_RHEL=${DOCKER_REPO_RHEL:-$DEFAULT_DOCKER_REPO_RHEL}
  log "Using Aliyun mirror for Docker package repositories (for better connectivity in China)"
fi

# Log configuration
log "Using Docker configuration:"
log "Registry Accelerator: $DOCKER_REGISTRY_ACCELERATOR"
log "Log Max Size: $DOCKER_LOG_MAX_SIZE"
log "Log Max File: $DOCKER_LOG_MAX_FILE"
log "Storage Driver: $DOCKER_STORAGE_DRIVER"
log "Docker Package Repository (Debian): $DOCKER_REPO_DEBIAN"
log "Docker Package Repository (RHEL): $DOCKER_REPO_RHEL"

log "Starting Docker installation for $OS_PRETTY_NAME..."

# Step 1: Configure Docker repository based on OS family
log "Configuring Docker package repository..."

# Allow users to choose repository in interactive mode
if [ "$NON_INTERACTIVE" != "true" ]; then
  if ! confirm_action "Do you want to use Aliyun mirror for Docker package repositories (recommended for users in China)?"; then
    DOCKER_REPO_DEBIAN=$OFFICIAL_DOCKER_REPO_DEBIAN
    DOCKER_REPO_RHEL=$OFFICIAL_DOCKER_REPO_RHEL
    log "Using official Docker package repositories"
  else
    DOCKER_REPO_DEBIAN=$DEFAULT_DOCKER_REPO_DEBIAN
    DOCKER_REPO_RHEL=$DEFAULT_DOCKER_REPO_RHEL
    log "Using Aliyun mirror for Docker package repositories"
  fi
fi

case "$OS_FAMILY" in
  "debian")
    # Install prerequisites
    execute "$PKG_INSTALL apt-transport-https ca-certificates curl gnupg lsb-release" \
      "Failed to install prerequisites" \
      "Prerequisites installed successfully"
    
    # Add Docker's official GPG key with retry
    max_retries=3
    retry_count=0
    gpg_success=false
    
    while [ $retry_count -lt $max_retries ] && [ "$gpg_success" = "false" ]; do
      if curl -fsSL $DOCKER_REPO_DEBIAN/$OS_NAME/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg; then
        gpg_success=true
        log "Docker GPG key added successfully"
      else
        retry_count=$((retry_count + 1))
        if [ $retry_count -lt $max_retries ]; then
          log_warning "Failed to add Docker GPG key, retrying ($retry_count/$max_retries)..."
          sleep 2
        else
          log_error "Failed to add Docker GPG key after $max_retries attempts"
          
          # If using Aliyun mirror failed, try official repository as fallback
          if [ "$DOCKER_REPO_DEBIAN" = "$DEFAULT_DOCKER_REPO_DEBIAN" ]; then
            log "Trying official Docker repository as fallback..."
            DOCKER_REPO_DEBIAN=$OFFICIAL_DOCKER_REPO_DEBIAN
            retry_count=0
          else
            exit 1
          fi
        fi
      fi
    done
    
    # Set up the stable repository
    execute "echo \"deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] $DOCKER_REPO_DEBIAN/$OS_NAME $(lsb_release -cs) stable\" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null" \
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
    
    # Add Docker repository with retry
    max_retries=3
    retry_count=0
    repo_success=false
    
    while [ $retry_count -lt $max_retries ] && [ "$repo_success" = "false" ]; do
      if $PKG_MANAGER config-manager --add-repo $DOCKER_REPO_RHEL; then
        repo_success=true
        log "Docker repository configured successfully"
      else
        retry_count=$((retry_count + 1))
        if [ $retry_count -lt $max_retries ]; then
          log_warning "Failed to add Docker repository, retrying ($retry_count/$max_retries)..."
          sleep 2
        else
          log_error "Failed to add Docker repository after $max_retries attempts"
          
          # If using Aliyun mirror failed, try official repository as fallback
          if [ "$DOCKER_REPO_RHEL" = "$DEFAULT_DOCKER_REPO_RHEL" ]; then
            log "Trying official Docker repository as fallback..."
            DOCKER_REPO_RHEL=$OFFICIAL_DOCKER_REPO_RHEL
            retry_count=0
          else
            exit 1
          fi
        fi
      fi
    done
    ;;
    
  *)
    log_error "Unsupported OS family: $OS_FAMILY"
    exit 1
    ;;
esac

# Step 2: Install Docker
log "Installing Docker packages..."

# Install Docker with retry
max_retries=3
retry_count=0
install_success=false

while [ $retry_count -lt $max_retries ] && [ "$install_success" = "false" ]; do
  if $PKG_INSTALL docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin; then
    install_success=true
    log "Docker installed successfully"
  else
    retry_count=$((retry_count + 1))
    if [ $retry_count -lt $max_retries ]; then
      log_warning "Docker installation failed, retrying ($retry_count/$max_retries)..."
      sleep 2
    else
      log_error "Docker installation failed after $max_retries attempts"
      exit 1
    fi
  fi
done

# Step 3: Configure Docker image acceleration
log "Configuring Docker image acceleration..."
execute "mkdir -p /etc/docker" \
  "Failed to create Docker configuration directory" \
  "Docker configuration directory created"

# Create Docker daemon configuration file with registry mirror
log "Setting up Docker daemon configuration..."

log "Detected registry accelerator: $DOCKER_REGISTRY_ACCELERATOR"

# In non-interactive mode, use the provided registry accelerator without prompting
# Otherwise, ask if user wants to use a different registry accelerator
if [ "$NON_INTERACTIVE" = "true" ] || confirm_action "Do you want to use the current registry accelerator ($DOCKER_REGISTRY_ACCELERATOR)?"; then
  log "Using registry accelerator: $DOCKER_REGISTRY_ACCELERATOR"
else
  read -p "Enter your preferred Docker registry accelerator URL: " custom_accelerator
  if [ -n "$custom_accelerator" ]; then
    DOCKER_REGISTRY_ACCELERATOR="$custom_accelerator"
    log "Using custom registry accelerator: $DOCKER_REGISTRY_ACCELERATOR"
  else
    log_warning "No accelerator provided, using default: $DOCKER_REGISTRY_ACCELERATOR"
  fi
fi

# Create the daemon.json file
cat > /etc/docker/daemon.json <<EOF
{
  "registry-mirrors": ["$DOCKER_REGISTRY_ACCELERATOR"],
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
log "Docker registry accelerator configuration:"
if execute "docker info | grep 'Registry Mirrors' -A 3" "Failed to get registry accelerator information" ""; then
  :  # No-op, continue
else
  log_warning "Could not verify registry accelerator configuration."
  log "Current daemon.json content:"
  cat /etc/docker/daemon.json
fi

log "Docker post-installation steps:"
log "1. To use Docker without sudo, add your user to the docker group:"
log "   sudo usermod -aG docker your-user"
log "2. Log out and log back in to apply the changes"
log "3. Test with: docker run hello-world"

log "Docker installation and configuration completed successfully."
