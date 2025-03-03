#!/bin/bash

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
