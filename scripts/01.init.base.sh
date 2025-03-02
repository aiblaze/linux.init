#!/bin/bash

# Initial setup script for the project
# This script may include basic configurations or environment setups required before executing other scripts.

# Update the system
sudo dnf update -y

# Install necessary dependencies
sudo dnf install -y curl wget git

# Set environment variables if needed
# export SOME_VARIABLE=value

echo "Initial setup completed."