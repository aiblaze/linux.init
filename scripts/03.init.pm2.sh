#!/bin/bash

# Source helper functions
source ./scripts/utils/helpers.sh

log_section "PM2 Process Manager Setup"

# Set default values for configuration variables
PM2_VERSION=${PM2_VERSION:-"latest"}

# Log configuration
log "Using PM2 configuration:"
log "PM2 Version: $PM2_VERSION"

# Check if PM2 is already installed
if command_exists "pm2"; then
    log "PM2 is already installed. Checking version..."
    pm2_version=$(pm2 -v)
    log "Current PM2 version: $pm2_version"
    
    # In non-interactive mode, always update PM2 if it's already installed
    # Otherwise, ask the user if they want to update
    if [ "$NON_INTERACTIVE" = "true" ] || confirm_action "Do you want to update PM2 to the latest version?"; then
        log "Updating PM2..."
        execute "npm install -g pm2@$PM2_VERSION" "Failed to update PM2" "PM2 updated successfully"
    else
        log "Skipping PM2 update."
    fi
else
    # Install PM2 globally
    log "Installing PM2 globally..."
    execute "npm install -g pm2@$PM2_VERSION" "Failed to install PM2" "PM2 installed successfully"
fi

# Verify PM2 installation
log "Verifying PM2 installation..."
if command_exists "pm2"; then
    pm2_version=$(pm2 -v)
    log "PM2 version: $pm2_version"
else
    log_error "PM2 installation verification failed."
    exit 1
fi

# Set up PM2 to start on boot
log "Setting up PM2 startup script..."
if command_exists "pm2"; then
    if execute "pm2 startup" "PM2 startup setup failed" "PM2 startup script generated"; then
        log "To complete PM2 startup setup, you may need to run the command shown above."
    fi
    
    # Save PM2 process list if there are any processes running
    if pm2 list | grep -q "online"; then
        log "Saving current PM2 process list..."
        execute "pm2 save" "Failed to save PM2 process list" "PM2 process list saved"
    fi
else
    log_error "PM2 command not found. Cannot set up startup script."
fi

log "PM2 setup completed."
