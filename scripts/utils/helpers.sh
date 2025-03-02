#!/bin/bash

# Utility functions for the init scripts

# Function to log messages
log() {
    local message="$1"
    echo "[INFO] $(date +'%Y-%m-%d %H:%M:%S') - $message"
}

# Function to log errors
log_error() {
    local message="$1"
    echo "[ERROR] $(date +'%Y-%m-%d %H:%M:%S') - $message" >&2
}

# Function to check if a command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Function to install a package if not already installed
install_if_not_installed() {
    local package="$1"
    if ! command_exists "$package"; then
        log "Installing $package..."
        sudo dnf install -y "$package"
    else
        log "$package is already installed."
    fi
}