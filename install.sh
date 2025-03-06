#!/bin/bash

# Source helper functions
source ./scripts/utils/helpers.sh

# Set strict error handling for non-interactive mode
if [ "$NON_INTERACTIVE" = "true" ]; then
  log "Running in non-interactive mode. Strict error handling enabled."
  set -e
fi

# Main installation script for setting up the environment on Linux
log_section "Linux Environment Setup"
log "Starting installation process..."

# Check if running as root
check_root

# Create log file for the installation
INSTALL_LOG_DIR="/var/log/linux.init"
INSTALL_LOG="$INSTALL_LOG_DIR/install-$(date +%Y%m%d-%H%M%S).log"
ensure_directory "$INSTALL_LOG_DIR"
log "Installation log will be saved to: $INSTALL_LOG"

# Function to run a script with error handling
run_script() {
  local script="$1"
  local description="$2"
  
  log_section "Running: $description"
  
  if bash "$script" 2>&1 | tee -a "$INSTALL_LOG"; then
    log "Successfully completed: $description"
    return 0
  else
    log_error "Failed to complete: $description"
    if [ "$NON_INTERACTIVE" = "true" ]; then
      log_error "Non-interactive mode: Aborting installation due to failure in: $description"
      exit 1
    elif confirm_action "Do you want to continue with the next step?"; then
      return 0
    else
      log_error "Installation aborted by user after failure in: $description"
      exit 1
    fi
  fi
}

# Display system information
display_system_info

# Display configuration
if [ "$NON_INTERACTIVE" = "true" ]; then
  log_section "Configuration Variables"
  log "NON_INTERACTIVE: $NON_INTERACTIVE"
  log "NODEJS_VERSION: ${NODEJS_VERSION:-default}"
  log "NODEJS_SOURCE: ${NODEJS_SOURCE:-default}"
  log "NODEJS_DEB_SOURCE: ${NODEJS_DEB_SOURCE:-default}"
  log "PNPM_VERSION: ${PNPM_VERSION:-default}"
  log "NVM_VERSION: ${NVM_VERSION:-default}"
  log "NVM_DIR: ${NVM_DIR:-default}"
  log "PM2_VERSION: ${PM2_VERSION:-default}"
  log "DOCKER_REGISTRY_MIRROR: ${DOCKER_REGISTRY_MIRROR:-default}"
  log "DOCKER_LOG_MAX_SIZE: ${DOCKER_LOG_MAX_SIZE:-default}"
  log "DOCKER_LOG_MAX_FILE: ${DOCKER_LOG_MAX_FILE:-default}"
  log "DOCKER_STORAGE_DRIVER: ${DOCKER_STORAGE_DRIVER:-default}"
  log "NPM_REGISTRY: ${NPM_REGISTRY:-default}"
fi

# Step 1: Run the initial setup script
run_script "./scripts/01.init.base.sh" "Initial system setup"

# Step 2: Install Node.js, PNPM, and NVM
run_script "./scripts/02.init.node.sh" "Node.js, PNPM, and NVM installation"

# Step 3: Install PM2
run_script "./scripts/03.init.pm2.sh" "PM2 installation"

# Step 4: Initialize Nginx
run_script "./scripts/04.init.nginx.sh" "Nginx setup"

# Step 5: Install Docker
run_script "./scripts/05.init.docker.sh" "Docker installation"

# Step Final: Initialize configuration files
run_script "./scripts/99.init.conf.sh" "Configuration files setup"

log_section "Installation Summary"
log "Installation completed successfully."
log "Installation log saved to: $INSTALL_LOG"
log "System is now set up with:"
log "- Node.js, PNPM, and NVM"
log "- PM2 process manager"
log "- Nginx web server"
log "- Docker container platform"
log "- System configurations"
