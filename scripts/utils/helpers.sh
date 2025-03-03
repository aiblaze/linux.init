#!/bin/bash

# Utility functions for the init scripts

# Colors for better output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to log messages
log() {
  local message="$1"
  echo -e "${GREEN}[INFO] $(date +'%Y-%m-%d %H:%M:%S') - $message${NC}"
}

# Function to log warnings
log_warning() {
  local message="$1"
  echo -e "${YELLOW}[WARNING] $(date +'%Y-%m-%d %H:%M:%S') - $message${NC}"
}

# Function to log errors
log_error() {
  local message="$1"
  echo -e "${RED}[ERROR] $(date +'%Y-%m-%d %H:%M:%S') - $message${NC}" >&2
}

# Function to log section headers
log_section() {
  local message="$1"
  echo -e "${BLUE}[SECTION] $(date +'%Y-%m-%d %H:%M:%S') - $message${NC}"
  echo -e "${BLUE}=====================================================${NC}"
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
    sudo dnf install -y "$package" || {
      log_error "Failed to install $package."
      return 1
    }
    log "$package installed successfully."
  else
    log "$package is already installed."
  fi
  return 0
}

# Function to check if script is run as root
check_root() {
  if [ "$(id -u)" -ne 0 ]; then
    log_error "This script must be run as root"
    exit 1
  fi
}

# Function to backup a directory
backup_directory() {
  local dir_to_backup="$1"
  local backup_dir="$2"
  
  if [ -d "$dir_to_backup" ]; then
    log "Backing up $dir_to_backup to $backup_dir..."
    if [ -d "$backup_dir" ]; then
      rm -rf "$backup_dir"
    fi
    cp -r "$dir_to_backup" "$backup_dir" || {
      log_error "Failed to backup $dir_to_backup"
      return 1
    }
    log "Backup completed successfully."
  else
    log_warning "Directory $dir_to_backup does not exist, skipping backup."
  fi
  return 0
}

# Function to confirm an action with the user
confirm_action() {
  local prompt="$1"
  local default="${2:-y}"
  
  local prompt_text
  if [[ "$default" = "y" ]]; then
    prompt_text="$prompt [Y/n]: "
  else
    prompt_text="$prompt [y/N]: "
  fi
  
  read -p "$prompt_text" -n 1 -r response
  echo
  
  if [[ -z "$response" ]]; then
    response=$default
  fi
  
  if [[ "$response" =~ ^[Yy]$ ]]; then
    return 0
  else
    return 1
  fi
}

# Function to execute a command with error handling
execute() {
  local cmd="$1"
  local error_msg="${2:-Command execution failed}"
  local success_msg="${3:-Command executed successfully}"
  
  log "Executing: $cmd"
  if eval "$cmd"; then
    log "$success_msg"
    return 0
  else
    log_error "$error_msg"
    return 1
  fi
}

# Function to check and create directories if they don't exist
ensure_directory() {
  local dir="$1"
  if [ ! -d "$dir" ]; then
    log "Creating directory: $dir"
    mkdir -p "$dir" || {
      log_error "Failed to create directory: $dir"
      return 1
    }
  fi
  return 0
}