#!/bin/bash

#############################################################
# 基础系统初始化脚本
# 
# 功能：
# - 更新系统软件包
# - 安装基础依赖工具（curl, wget, git）
# - 根据操作系统类型安装额外的必要工具
# - 为后续安装脚本准备环境
#
# 支持的系统：
# - Debian/Ubuntu 系列
# - RHEL/CentOS/AlmaLinux 系列
#############################################################

# Initial setup script for the project
source ./scripts/utils/helpers.sh

log_section "Initial System Setup"

# Display system information
display_system_info

log "Starting initial system setup for $OS_PRETTY_NAME..."

# Update the system
log "Updating system packages..."
if sudo $PKG_UPDATE; then
    log "System packages updated successfully."
else
    log_error "Failed to update system packages."
    exit 1
fi

# Install necessary dependencies
log "Installing required dependencies..."
if sudo $PKG_INSTALL curl wget git; then
    log "Dependencies installed successfully."
else
    log_error "Failed to install dependencies."
    exit 1
fi

# Install additional useful tools based on OS family
log "Installing additional useful tools..."
case "$OS_FAMILY" in
    "debian")
        sudo $PKG_INSTALL apt-transport-https ca-certificates gnupg lsb-release software-properties-common
        ;;
    "rhel")
        sudo $PKG_INSTALL epel-release yum-utils
        ;;
    *)
        log_warning "Unknown OS family: $OS_FAMILY. Skipping additional tools installation."
        ;;
esac

log "Initial setup completed successfully."
