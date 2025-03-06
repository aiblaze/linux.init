#!/bin/bash

# Utility functions for the init scripts

# Source OS detection script
source ./scripts/utils/os_detection.sh

# Set default value for non-interactive mode
NON_INTERACTIVE=${NON_INTERACTIVE:-false}

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
    sudo $PKG_INSTALL "$package" || {
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
  
  # In non-interactive mode, always return the default value
  if [ "$NON_INTERACTIVE" = "true" ]; then
    if [[ "$default" = "y" ]]; then
      log "Non-interactive mode: Automatically choosing default option (Yes) for: $prompt"
      return 0
    else
      log "Non-interactive mode: Automatically choosing default option (No) for: $prompt"
      return 1
    fi
  fi
  
  # Interactive mode logic
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

# Function to display system information
display_system_info() {
  log_section "System Information"
  display_os_info
  log "Kernel: $(uname -r)"
  log "Architecture: $(uname -m)"
  log "Hostname: $(hostname)"
}

# Function to add a repository based on OS family
add_repository() {
  local repo_name="$1"
  local repo_url="$2"
  
  log "Adding repository: $repo_name"
  
  case "$OS_FAMILY" in
    "debian")
      if ! command_exists "add-apt-repository"; then
        sudo $PKG_INSTALL software-properties-common
      fi
      sudo add-apt-repository -y "$repo_url" || {
        log_error "Failed to add repository: $repo_name"
        return 1
      }
      sudo $PKG_UPDATE
      ;;
    "rhel")
      if ! command_exists "dnf-plugins-core" && [ "$PKG_MANAGER" = "dnf" ]; then
        sudo $PKG_INSTALL dnf-plugins-core
      fi
      sudo $PKG_MANAGER config-manager --add-repo "$repo_url" || {
        log_error "Failed to add repository: $repo_name"
        return 1
      }
      ;;
    *)
      log_error "Unsupported OS family for adding repository: $OS_FAMILY"
      return 1
      ;;
  esac
  
  log "Repository added successfully: $repo_name"
  return 0
}