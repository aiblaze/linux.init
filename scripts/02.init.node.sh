#!/bin/bash

# Source helper functions
source ./scripts/utils/helpers.sh

log_section "Node.js Environment Setup"

# Set default values for configuration variables
NODEJS_VERSION=${NODEJS_VERSION:-"23.x"}
NODEJS_SOURCE=${NODEJS_SOURCE:-"https://rpm.nodesource.com/setup_${NODEJS_VERSION}"}
NODEJS_DEB_SOURCE=${NODEJS_DEB_SOURCE:-"https://deb.nodesource.com/setup_${NODEJS_VERSION}"}
PNPM_VERSION=${PNPM_VERSION:-"latest"}
NVM_VERSION=${NVM_VERSION:-"0.40.1"}
NVM_DIR=${NVM_DIR:-"$HOME/.nvm"}
NVM_INSTALL_URL=${NVM_INSTALL_URL:-"https://raw.githubusercontent.com/nvm-sh/nvm/v${NVM_VERSION}/install.sh"}

# Log configuration
log "Using configuration:"
log "Node.js Version: $NODEJS_VERSION"
log "Node.js Source (RPM): $NODEJS_SOURCE"
log "Node.js Source (DEB): $NODEJS_DEB_SOURCE"
log "PNPM Version: $PNPM_VERSION"
log "NVM Version: $NVM_VERSION"
log "NVM Directory: $NVM_DIR"
log "NVM Install URL: $NVM_INSTALL_URL"

# Update the system
log "Updating system packages..."
execute "$PKG_UPDATE" "Failed to update system packages" "System packages updated successfully"

# Install Node.js
log "Installing Node.js..."
if ! command_exists "node"; then
  case "$OS_FAMILY" in
    "debian")
      execute "curl -fsSL $NODEJS_DEB_SOURCE | sudo bash -" "Failed to setup Node.js repository" "Node.js repository setup completed"
      execute "$PKG_INSTALL nodejs" "Failed to install Node.js" "Node.js installed successfully"
      ;;
    "rhel")
      execute "curl -fsSL $NODEJS_SOURCE | sudo bash -" "Failed to setup Node.js repository" "Node.js repository setup completed"
      execute "$PKG_INSTALL nodejs" "Failed to install Node.js" "Node.js installed successfully"
      ;;
    *)
      log_error "Unsupported OS family: $OS_FAMILY"
      exit 1
      ;;
  esac
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
  if [ "$PNPM_VERSION" = "latest" ]; then
    execute "sudo npm install -g pnpm" "Failed to install PNPM" "PNPM installed successfully"
  else
    execute "sudo npm install -g pnpm@$PNPM_VERSION" "Failed to install PNPM version $PNPM_VERSION" "PNPM version $PNPM_VERSION installed successfully"
  fi
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

if [ ! -d "$NVM_DIR" ]; then
  log "Downloading NVM..."
  execute "curl -o- $NVM_INSTALL_URL | bash" "Failed to download and install NVM" "NVM downloaded successfully"
  
  # Load NVM
  log "Loading NVM..."
  export NVM_DIR="$NVM_DIR"
  [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
else
  log "NVM directory already exists. Skipping installation."
  # Load NVM anyway
  export NVM_DIR="$NVM_DIR"
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
