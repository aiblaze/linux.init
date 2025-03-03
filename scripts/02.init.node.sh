#!/bin/bash

# Source helper functions
source ./scripts/utils/helpers.sh

log_section "Node.js Environment Setup"

# Update the system
log "Updating system packages..."
execute "sudo dnf update -y" "Failed to update system packages" "System packages updated successfully"

# Install Node.js
log "Installing Node.js..."
if ! command_exists "node"; then
  execute "curl -fsSL https://rpm.nodesource.com/setup_23.x | sudo bash -" "Failed to setup Node.js repository" "Node.js repository setup completed"
  execute "sudo dnf install -y nodejs" "Failed to install Node.js" "Node.js installed successfully"
else
  log "Node.js is already installed."
fi

# Verify Node.js installation
log "Verifying Node.js installation..."
if command_exists "node"; then
  node_version=$(node -v)
  log "Node.js version: $node_version"
else
  log_error "Node.js installation verification failed."
  exit 1
fi

# Verify npm installation
log "Verifying npm installation..."
if command_exists "npm"; then
  npm_version=$(npm -v)
  log "npm version: $npm_version"
else
  log_error "npm installation verification failed."
  exit 1
fi

# Install PNPM
log "Installing PNPM..."
if ! command_exists "pnpm"; then
  execute "sudo npm install -g pnpm" "Failed to install PNPM" "PNPM installed successfully"
else
  log "PNPM is already installed."
fi

# Verify PNPM installation
log "Verifying PNPM installation..."
if command_exists "pnpm"; then
  pnpm_version=$(pnpm -v)
  log "PNPM version: $pnpm_version"
else
  log_error "PNPM installation verification failed."
  exit 1
fi

# Install NVM
log "Installing NVM..."
NVM_VERSION="v0.40.1"
NVM_DIR="$HOME/.nvm"

if [ ! -d "$NVM_DIR" ]; then
  log "Downloading NVM..."
  execute "curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/$NVM_VERSION/install.sh | bash" "Failed to download and install NVM" "NVM downloaded successfully"
  
  # Load NVM
  log "Loading NVM..."
  export NVM_DIR="$HOME/.nvm"
  [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
else
  log "NVM directory already exists. Skipping installation."
  # Load NVM anyway
  export NVM_DIR="$HOME/.nvm"
  [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
fi

# Verify NVM installation
log "Verifying NVM installation..."
if command_exists "nvm"; then
  nvm_version=$(nvm --version)
  log "NVM version: $nvm_version"
else
  log_warning "NVM command not available in current shell. You may need to restart your shell or source ~/.bashrc"
  log_warning "NVM installation might have completed but cannot be verified."
fi

log "Node.js environment setup completed."
