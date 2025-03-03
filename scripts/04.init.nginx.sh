#!/bin/bash

# Source helper functions
source ./scripts/utils/helpers.sh

log_section "Nginx Web Server Setup"

# Check if running as root
check_root

# Check if nginx is already installed
log "Checking if Nginx is already installed..."
if command_exists "nginx"; then
  log "Nginx is already installed."
  nginx_version=$(nginx -v 2>&1)
  log "Nginx version: $nginx_version"
  
  # Check if nginx is running and stop it if it is
  log "Checking if Nginx is running..."
  if systemctl is-active --quiet nginx; then
    log "Stopping Nginx service..."
    if execute "systemctl stop nginx" "Failed to stop Nginx service" "Nginx service stopped successfully"; then
      :  # No-op, continue
    else
      exit 1
    fi
  else
    log "Nginx is not running."
  fi
else
  log "Installing Nginx..."
  if execute "dnf install -y nginx" "Failed to install Nginx" "Nginx installed successfully"; then
    :  # No-op, continue
  else
    exit 1
  fi
fi

# Backup /etc/nginx directory
log "Backing up /etc/nginx to /etc/nginx-previous..."
if [ -d "/etc/nginx" ]; then
  if backup_directory "/etc/nginx" "/etc/nginx-previous"; then
    :  # No-op, continue
  else
    exit 1
  fi
else
  log_warning "No /etc/nginx directory found to backup."
fi

# Ask for confirmation before replacing configuration
log "This script will replace your current Nginx configuration with h5bp/server-configs-nginx."
if confirm_action "Do you want to continue?"; then
  :  # No-op, continue
else
  log "Operation cancelled."
  exit 0
fi

# Clone the h5bp/server-configs-nginx repository
log "Cloning h5bp/server-configs-nginx repository..."

# Ensure git is installed
if ! command_exists "git"; then
  log "Installing git..."
  execute "dnf install -y git" "Failed to install git" "Git installed successfully"
fi

# Create a temporary directory for the clone to prevent issues if cloning fails
TEMP_NGINX_DIR=$(mktemp -d)
log "Created temporary directory: $TEMP_NGINX_DIR"

# Clone the repository to the temporary directory
if execute "git clone https://github.com/h5bp/server-configs-nginx.git $TEMP_NGINX_DIR" "Failed to clone repository" "Repository cloned successfully"; then
  # Only remove existing nginx directory after successful clone
  if [ -d "/etc/nginx" ]; then
    log "Removing existing /etc/nginx directory..."
    execute "rm -rf /etc/nginx" "Failed to remove existing /etc/nginx directory" "Removed existing /etc/nginx directory"
  fi
  
  # Move the temporary directory to /etc/nginx
  execute "mv $TEMP_NGINX_DIR /etc/nginx" "Failed to move configuration files to /etc/nginx" "Moved configuration files to /etc/nginx"
else
  log_error "Failed to clone repository."
  # Ask user if they want to restore backup
  if [ -d "/etc/nginx-previous" ]; then
    if confirm_action "Would you like to restore the previous Nginx configuration?"; then
      log "Restoring backup..."
      execute "cp -r /etc/nginx-previous /etc/nginx" "Failed to restore backup" "Backup restored successfully"
    else
      log_warning "Backup not restored. Nginx may not function properly."
    fi
  fi
  exit 1
fi

# Add nginx user and group (AlmaLinux standard)
log "Adding nginx user and group..."
# Check if group exists
if ! getent group nginx > /dev/null; then
  execute "groupadd nginx" "Failed to create nginx group" "Created nginx group"
else
  log "Nginx group already exists."
fi

# Check if user exists
if ! id -u nginx > /dev/null 2>&1; then
  execute "useradd -r -g nginx -s /usr/sbin/nologin -c 'nginx user' nginx" "Failed to create nginx user" "Created nginx user"
else
  log "Nginx user already exists."
fi

# Add www-data user and group (Alternative for compatibility)
log "Adding www-data user and group..."
# Check if group exists
if ! getent group www-data > /dev/null; then
  execute "groupadd www-data" "Failed to create www-data group" "Created www-data group"
else
  log "www-data group already exists."
fi

# Check if user exists
if ! id -u www-data > /dev/null 2>&1; then
  execute "useradd -r -g www-data -s /usr/sbin/nologin -c 'www data' www-data" "Failed to create www-data user" "Created www-data user"
else
  log "www-data user already exists."
fi

# Test nginx configuration
log "Testing Nginx configuration..."
if execute "nginx -t" "Nginx configuration test failed" "Nginx configuration test passed"; then
  :  # No-op, continue
else
  # Ask user if they want to restore backup
  if [ -d "/etc/nginx-previous" ]; then
    if confirm_action "Would you like to restore the previous Nginx configuration?"; then
      log "Restoring backup..."
      execute "rm -rf /etc/nginx" "Failed to remove broken configuration" "Removed broken configuration"
      execute "cp -r /etc/nginx-previous /etc/nginx" "Failed to restore backup" "Backup restored successfully"
    else
      log_warning "Backup not restored. Nginx may not function properly."
    fi
  fi
  exit 1
fi

# Start/restart nginx service
log "Starting Nginx service..."
if execute "systemctl enable nginx" "Failed to enable Nginx service" "Nginx service enabled"; then
  :  # No-op, continue
else
  exit 1
fi

if execute "systemctl restart nginx" "Failed to start Nginx service" "Nginx service started successfully"; then
  :  # No-op, continue
else
  exit 1
fi

log "Nginx setup completed successfully."
