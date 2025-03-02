#!/bin/bash

# Main installation script for setting up the environment on AlmaLinux

# Step 1: Run the initial setup script
# bash ./scripts/01.init.base.sh

# Step 2: Install Node.js, PNPM, and NVM
bash ./scripts/02.init.node.sh

# Step 3: Install PM2
bash ./scripts/03.init.pm2.sh

# Step 4: Initialize Nginx
bash ./scripts/04.init.nginx.sh

# Step 5: Install Docker
bash ./scripts/05.init.docker.sh

# Step Final: Initialize configuration files
bash ./scripts/99.init.conf.sh

echo "Installation completed successfully."