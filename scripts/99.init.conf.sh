#!/bin/bash

#############################################################
# 系统配置文件初始化脚本
# 
# 功能：
# - 安全地复制配置文件到系统目录（自动创建备份）
# - 配置 SSH 服务安全参数
# - 设置 NPM 镜像源（可选）
#
# 环境变量：
# - NPM_REGISTRY: NPM 镜像源地址 (可选)
#
# 依赖：
# - 部分操作需要 root 权限
#############################################################

# Source helper functions
source ./scripts/utils/helpers.sh

log_section "Initializing Configuration Files"

# Set default values for configuration variables
NPM_REGISTRY=${NPM_REGISTRY:-""}

# Log configuration
if [ -n "$NPM_REGISTRY" ]; then
    log "Using NPM configuration:"
    log "NPM Registry: $NPM_REGISTRY"
fi

# Check if running with appropriate permissions
log "Checking permissions for SSH configuration..."
if [ ! -w "/etc/ssh" ] && [ "$(id -u)" -ne 0 ]; then
    log_warning "This script needs root privileges to copy files to /etc/ssh"
    log_warning "Running parts of the script with sudo..."
fi

# Function to copy files with backup
safe_copy() {
    local src="$1"
    local dest="$2"
    local require_sudo="${3:-false}"
    local cmd_prefix=""
    
    if [[ "$require_sudo" == "true" ]]; then
        cmd_prefix="sudo "
    fi
    
    # Check if source exists
    if [ ! -e "$src" ]; then
        log_error "Source path does not exist: $src"
        return 1
    fi
    
    # Create backup if destination exists
    if [ -e "$dest" ]; then
        log "Creating backup of $dest..."
        local backup_path="${dest}.bak.$(date +%Y%m%d%H%M%S)"
        if $cmd_prefix cp -a "$dest" "$backup_path"; then
            log "Backup created: $backup_path"
        else
            log_error "Failed to create backup of $dest"
            return 1
        fi
    fi
    
    # Copy the file/directory
    log "Copying $src to $dest..."
    if $cmd_prefix cp -rv "$src" "$dest"; then
        log "Successfully copied to $dest"
        return 0
    else
        log_error "Failed to copy to $dest"
        return 1
    fi
}

# Copy home configuration files
log "Copying home configuration files..."

# Check if home directory configs exist
if [ -d "./configs/home" ]; then
    # Copy each file individually to handle hidden files correctly
    for file in ./configs/home/*; do
        if [ -f "$file" ]; then
            filename=$(basename "$file")
            safe_copy "$file" "$HOME/$filename"
        fi
    done
    
    # Check for hidden files separately
    for file in ./configs/home/.*; do
        if [ -f "$file" ] && [ "$(basename "$file")" != "." ] && [ "$(basename "$file")" != ".." ]; then
            filename=$(basename "$file")
            safe_copy "$file" "$HOME/$filename"
        fi
    done
else
    log_error "The 'configs/home' directory doesn't exist in the current location"
    exit 1
fi

# Copy SSH configuration files
log "Copying SSH configuration files..."

# Check if SSH configs exist
if [ -d "./configs/ssh" ]; then
    # First try without sudo
    if [ -w "/etc/ssh" ]; then
        # Directory is writable, copy directly
        for file in $(find ./configs/ssh -type f); do
            rel_path=${file#"./configs/ssh/"}
            dest_path="/etc/ssh/$rel_path"
            dest_dir=$(dirname "$dest_path")
            
            # Create destination directory if it doesn't exist
            if [ ! -d "$dest_dir" ]; then
                if ! mkdir -p "$dest_dir"; then
                    log_error "Failed to create directory: $dest_dir"
                    continue
                fi
            fi
            
            safe_copy "$file" "$dest_path"
        done
    else
        # Need sudo privileges
        log "Using sudo to copy SSH configuration files..."
        for file in $(find ./configs/ssh -type f); do
            rel_path=${file#"./configs/ssh/"}
            dest_path="/etc/ssh/$rel_path"
            dest_dir=$(dirname "$dest_path")
            
            # Create destination directory if it doesn't exist
            if [ ! -d "$dest_dir" ]; then
                if ! sudo mkdir -p "$dest_dir"; then
                    log_error "Failed to create directory: $dest_dir"
                    continue
                fi
            fi
            
            safe_copy "$file" "$dest_path" true
        done
    fi
    
    # Reload SSH service to apply new configuration
    log "Reloading SSH service to apply new configuration..."
    if command_exists "systemctl"; then
        execute "sudo systemctl reload sshd" "Failed to reload SSH service" "SSH service reloaded successfully"
    else
        execute "sudo service sshd reload" "Failed to reload SSH service" "SSH service reloaded successfully"
    fi
else
    log_warning "The 'configs/ssh' directory doesn't exist in the current location. Skipping SSH configuration."
fi

# Configure NPM registry if specified
if [ -n "$NPM_REGISTRY" ] && command_exists "npm"; then
    log "Configuring NPM registry..."
    execute "npm config set registry $NPM_REGISTRY" "Failed to set NPM registry" "NPM registry set to $NPM_REGISTRY"
    
    # Verify the registry setting
    npm_current_registry=$(npm config get registry)
    log "Current NPM registry: $npm_current_registry"
fi

log "Configuration files initialization completed successfully!"
