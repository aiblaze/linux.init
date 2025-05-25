#!/bin/bash

#############################################################
# Bun 运行时安装脚本
# 
# 功能：
# - 检查 Bun 是否已安装
# - 安装 Bun 运行时环境
# - 配置环境变量
# - 验证安装结果
#############################################################

# 引入工具函数
source ./scripts/utils/helpers.sh

log_section "Bun Runtime Setup"

# 检查 Bun 是否已安装
if command_exists "bun"; then
    log "Bun is already installed."
    bun_version=$(bun --version)
    log "Current Bun version: $bun_version"
    exit 0
fi

# 安装 Bun
log "Installing Bun..."
execute "curl -fsSL https://bun.sh/install | bash" "Failed to install Bun" "Bun installed successfully"

# 配置环境变量
export BUN_INSTALL="$HOME/.bun"
export PATH="$BUN_INSTALL/bin:$PATH"

# 验证安装
log "Verifying Bun installation..."
if command_exists "bun"; then
    bun_version=$(bun --version)
    log "Bun version: $bun_version"
else
    log_error "Bun installation verification failed."
    exit 1
fi

log "Bun setup completed."