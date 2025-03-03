#!/bin/bash

# Initial setup script for the project
source ./scripts/utils/helpers.sh

log "Starting initial system setup..."

# Update the system
log "Updating system packages..."
if sudo dnf update -y; then
    log "System packages updated successfully."
else
    log_error "Failed to update system packages."
    exit 1
fi

# Install necessary dependencies
log "Installing required dependencies..."
if sudo dnf install -y curl wget git; then
    log "Dependencies installed successfully."
else
    log_error "Failed to install dependencies."
    exit 1
fi

log "Initial setup completed successfully."
