#!/bin/bash

# Update the system
sudo dnf update -y

# Install Node.js
curl -fsSL https://rpm.nodesource.com/setup_23.x | sudo bash -
sudo dnf install -y nodejs

# Verify Node.js installation
node -v
npm -v

# Install PNPM
sudo npm install -g pnpm

# Verify PNPM installation
pnpm -v

# Install NVM
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.1/install.sh | bash

# Load NVM
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"

# Verify NVM installation
nvm -v