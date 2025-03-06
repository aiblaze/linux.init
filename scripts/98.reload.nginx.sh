#!/bin/bash

#############################################################
# Nginx 服务重载脚本
# 
# 功能：
# - 测试 Nginx 配置文件语法
# - 安全地重载 Nginx 配置（不中断连接）
# - 如果重载失败，尝试重启 Nginx 服务
# - 验证 Nginx 服务状态
# - 显示详细的错误信息和故障排除提示
#
# 使用场景：
# - 更新 SSL 证书后
# - 修改 Nginx 配置文件后
# - 添加或修改虚拟主机配置后
#
# 依赖：
# - 需要 root 权限
# - 需要已安装 Nginx
#############################################################

# Source helper functions
source ./scripts/utils/helpers.sh

log_section "Nginx Service Reload"

# Check if running as root
check_root

# Check if nginx is installed
log "Checking if Nginx is installed..."
if ! command_exists "nginx"; then
  log_error "Nginx is not installed or not in PATH"
  exit 1
fi

# Test nginx configuration
log "Testing Nginx configuration..."
if execute "nginx -t" "Nginx configuration test failed" "Nginx configuration is valid"; then
  :  # No-op, continue
else
  log_error "Nginx configuration test failed. Please fix the configuration errors."
  exit 1
fi

# Check nginx service status
log "Checking Nginx service status..."
if systemctl is-active --quiet nginx; then
  log "Nginx is currently running. Attempting reload..."
  
  # Try to reload first (more graceful)
  if execute "systemctl reload nginx" "Failed to reload Nginx" "Nginx successfully reloaded"; then
    log "SSL certificates have been applied without connection interruption."
  else
    log_warning "Reload failed, attempting restart..."
    
    # If reload fails, try restart
    if execute "systemctl restart nginx" "Failed to restart Nginx" "Nginx successfully restarted"; then
      log "Nginx has been restarted with the new SSL certificates."
    else
      log_error "Failed to restart Nginx service."
      
      # Display relevant logs for troubleshooting
      log_warning "Last few lines from Nginx error log:"
      execute "tail -n 20 /var/log/nginx/error.log" "" ""
      
      # Check for permission issues
      log_warning "Checking for permission issues..."
      execute "ls -la /etc/nginx/ssl/" "" ""
      
      exit 1
    fi
  fi
else
  log_warning "Nginx is not running. Starting Nginx service..."
  
  # Start nginx if it's not running
  if execute "systemctl start nginx" "Failed to start Nginx" "Nginx successfully started"; then
    log "Nginx has been started with the new SSL certificates."
  else
    log_error "Failed to start Nginx service."
    exit 1
  fi
fi

# Final verification
log "Verifying Nginx service status..."
if systemctl is-active --quiet nginx; then
  log_section "Nginx Service Status"
  execute "systemctl status nginx --no-pager" "" ""
  log "Nginx is running properly with the new SSL certificates."
else
  log_error "Nginx is not running after reload/restart attempt."
  exit 1
fi

log "Nginx reload completed successfully."
exit 0
