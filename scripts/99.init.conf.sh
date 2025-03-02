#!/bin/bash

#-- Script functions:
#-- 1. Copy files from the 'configs/home' directory to the user's home directory
#-- 2. Copy files from the 'configs/ssh' directory to the '/etc/ssh/' directory

# Exit on any error
set -e

# Function to display error messages
error_exit() {
    echo "ERROR: $1" >&2
    exit 1
}

# Display welcome message
echo "Starting initialization script..."

# Check if home directory exists in current location
if [ ! -d "./configs/home" ]; then
    error_exit "The 'configs/home' directory doesn't exist in the current location"
fi

# Check if ssh directory exists in current location
if [ ! -d "./configs/ssh" ]; then
    error_exit "The 'configs/ssh' directory doesn't exist in the current location"
fi

# Copy files from home directory to user's home directory
echo "Copying files from './configs/home' to your home directory (~)..."
cp -rv ./configs/home/* ~/
echo "Home files copied successfully."

# Copy files from ssh directory to /etc/ssh/ (may require sudo)
echo "Copying files from './configs/ssh' to /etc/ssh/..."
if [ -w /etc/ssh ]; then
    # User has write permission
    cp -rv ./configs/ssh/* /etc/ssh/
else
    # User doesn't have write permission, use sudo
    echo "Elevated privileges required to copy to /etc/ssh/"
    sudo cp -rv ./configs/ssh/* /etc/ssh/
fi
echo "SSH files copied successfully."

echo "Conf files initialization completed successfully!"
