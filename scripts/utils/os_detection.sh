#!/bin/bash

# OS detection script to determine the Linux distribution and package manager

# Function to detect the OS type
detect_os() {
  if [ -f /etc/os-release ]; then
    . /etc/os-release
    OS_NAME=$ID
    OS_VERSION=$VERSION_ID
    OS_PRETTY_NAME=$PRETTY_NAME
  elif [ -f /etc/lsb-release ]; then
    . /etc/lsb-release
    OS_NAME=$DISTRIB_ID
    OS_VERSION=$DISTRIB_RELEASE
    OS_PRETTY_NAME="$DISTRIB_ID $DISTRIB_RELEASE"
  elif [ -f /etc/redhat-release ]; then
    OS_NAME=$(cat /etc/redhat-release | awk '{print tolower($1)}')
    OS_VERSION=$(cat /etc/redhat-release | grep -o '[0-9.]*' | head -n1)
    OS_PRETTY_NAME=$(cat /etc/redhat-release)
  else
    OS_NAME="unknown"
    OS_VERSION="unknown"
    OS_PRETTY_NAME="Unknown Linux Distribution"
  fi

  # Normalize OS names
  case "$OS_NAME" in
    "ubuntu"|"debian"|"linuxmint")
      OS_FAMILY="debian"
      PKG_MANAGER="apt"
      PKG_UPDATE="apt update -y"
      PKG_INSTALL="apt install -y"
      ;;
    "centos"|"rhel"|"fedora"|"rocky"|"almalinux")
      OS_FAMILY="rhel"
      PKG_MANAGER="dnf"
      if ! command -v dnf >/dev/null 2>&1 && command -v yum >/dev/null 2>&1; then
        PKG_MANAGER="yum"
      fi
      PKG_UPDATE="$PKG_MANAGER update -y"
      PKG_INSTALL="$PKG_MANAGER install -y"
      ;;
    *)
      OS_FAMILY="unknown"
      if command -v apt >/dev/null 2>&1; then
        PKG_MANAGER="apt"
        PKG_UPDATE="apt update -y"
        PKG_INSTALL="apt install -y"
      elif command -v dnf >/dev/null 2>&1; then
        PKG_MANAGER="dnf"
        PKG_UPDATE="dnf update -y"
        PKG_INSTALL="dnf install -y"
      elif command -v yum >/dev/null 2>&1; then
        PKG_MANAGER="yum"
        PKG_UPDATE="yum update -y"
        PKG_INSTALL="yum install -y"
      else
        PKG_MANAGER="unknown"
        PKG_UPDATE="echo 'Unknown package manager'"
        PKG_INSTALL="echo 'Unknown package manager'"
      fi
      ;;
  esac

  # Export variables
  export OS_NAME
  export OS_VERSION
  export OS_PRETTY_NAME
  export OS_FAMILY
  export PKG_MANAGER
  export PKG_UPDATE
  export PKG_INSTALL
}

# Call the function to detect OS
detect_os

# Function to display OS information
display_os_info() {
  echo "OS Name: $OS_NAME"
  echo "OS Version: $OS_VERSION"
  echo "OS Pretty Name: $OS_PRETTY_NAME"
  echo "OS Family: $OS_FAMILY"
  echo "Package Manager: $PKG_MANAGER"
  echo "Update Command: $PKG_UPDATE"
  echo "Install Command: $PKG_INSTALL"
} 