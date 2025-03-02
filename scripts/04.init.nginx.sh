#!/bin/bash

# Script to setup nginx configuration

# Set colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
NC='\033[0m' # No Color

# Check if running as root
if [ "$(id -u)" -ne 0 ]; then
    echo -e "${RED}This script must be run as root${NC}" >&2
    exit 1
fi

# Check if nginx is already installed
echo -e "${YELLOW}Checking if Nginx is already installed...${NC}"
if command -v nginx &> /dev/null; then
    echo -e "${GREEN}Nginx is already installed.${NC}"
    nginx -v
    
    # Check if nginx is running and stop it if it is
    echo -e "${YELLOW}Checking if Nginx is running...${NC}"
    if systemctl is-active --quiet nginx; then
        echo -e "${YELLOW}Stopping Nginx service...${NC}"
        systemctl stop nginx
        if [ $? -ne 0 ]; then
            echo -e "${RED}Failed to stop Nginx service.${NC}" >&2
            exit 1
        fi
        echo -e "${GREEN}Nginx service stopped.${NC}"
    else
        echo -e "${GREEN}Nginx is not running.${NC}"
    fi
else
    echo -e "${YELLOW}Installing Nginx...${NC}"
    dnf install -y nginx
    if [ $? -ne 0 ]; then
        echo -e "${RED}Failed to install Nginx.${NC}" >&2
        exit 1
    fi
    echo -e "${GREEN}Nginx installed successfully.${NC}"
fi

# Backup /etc/nginx directory
echo -e "${YELLOW}Backing up /etc/nginx to /etc/nginx-previous...${NC}"
if [ -d "/etc/nginx" ]; then
    if [ -d "/etc/nginx-previous" ]; then
        rm -rf /etc/nginx-previous
    fi
    cp -r /etc/nginx /etc/nginx-previous
    echo -e "${GREEN}Backup completed.${NC}"
else
    echo -e "${YELLOW}No /etc/nginx directory found to backup.${NC}"
fi

# Ask for confirmation before replacing configuration
echo -e "${YELLOW}This script will replace your current Nginx configuration with h5bp/server-configs-nginx.${NC}"
read -p "Do you want to continue? (y/n): " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo -e "${YELLOW}Operation cancelled.${NC}"
    exit 0
fi

# Clone the h5bp/server-configs-nginx repository
echo -e "${YELLOW}Cloning h5bp/server-configs-nginx repository...${NC}"
# Ensure git is installed
if ! command -v git &> /dev/null; then
    echo -e "${YELLOW}Installing git...${NC}"
    dnf install -y git
fi

# Remove existing nginx directory if it exists
if [ -d "/etc/nginx" ]; then
    rm -rf /etc/nginx
fi

# Clone the repository
git clone https://github.com/h5bp/server-configs-nginx.git /etc/nginx
if [ $? -ne 0 ]; then
    echo -e "${RED}Failed to clone repository.${NC}" >&2
    # Ask user if they want to restore backup
    if [ -d "/etc/nginx-previous" ]; then
        echo -e "${YELLOW}Would you like to restore the previous Nginx configuration?${NC}"
        read -p "Restore backup? (y/n): " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            echo -e "${YELLOW}Restoring backup...${NC}"
            cp -r /etc/nginx-previous /etc/nginx
            echo -e "${GREEN}Backup restored.${NC}"
        else
            echo -e "${YELLOW}Backup not restored. Nginx may not function properly.${NC}"
        fi
    fi
    exit 1
fi

# Add nginx user and group (AlmaLinux standard)
echo -e "${YELLOW}Adding nginx user and group...${NC}"
# Check if group exists
if ! getent group nginx > /dev/null; then
    groupadd nginx
    echo -e "${GREEN}Created nginx group.${NC}"
else
    echo -e "${GREEN}Nginx group already exists.${NC}"
fi

# Check if user exists
if ! id -u nginx > /dev/null 2>&1; then
    useradd -r -g nginx -s /usr/sbin/nologin -c "nginx user" nginx
    echo -e "${GREEN}Created nginx user.${NC}"
else
    echo -e "${GREEN}Nginx user already exists.${NC}"
fi

# Add www-data user and group (Alternative for compatibility)
echo -e "${YELLOW}Adding www-data user and group...${NC}"
# Check if group exists
if ! getent group www-data > /dev/null; then
    groupadd www-data
    echo -e "${GREEN}Created www-data group.${NC}"
else
    echo -e "${GREEN}www-data group already exists.${NC}"
fi

# Check if user exists
if ! id -u www-data > /dev/null 2>&1; then
    useradd -r -g www-data -s /usr/sbin/nologin -c "www data" www-data
    echo -e "${GREEN}Created www-data user.${NC}"
else
    echo -e "${GREEN}www-data user already exists.${NC}"
fi

# Test nginx configuration
echo -e "${YELLOW}Testing Nginx configuration...${NC}"
nginx -t
if [ $? -ne 0 ]; then
    echo -e "${RED}Nginx configuration test failed.${NC}" >&2
    # Ask user if they want to restore backup
    if [ -d "/etc/nginx-previous" ]; then
        echo -e "${YELLOW}Would you like to restore the previous Nginx configuration?${NC}"
        read -p "Restore backup? (y/n): " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            echo -e "${YELLOW}Restoring backup...${NC}"
            rm -rf /etc/nginx
            cp -r /etc/nginx-previous /etc/nginx
            echo -e "${GREEN}Backup restored.${NC}"
        else
            echo -e "${YELLOW}Backup not restored. Nginx may not function properly.${NC}"
        fi
    fi
    exit 1
fi

# Start/restart nginx service
echo -e "${YELLOW}Starting Nginx service...${NC}"
systemctl enable nginx
systemctl restart nginx
if [ $? -ne 0 ]; then
    echo -e "${RED}Failed to start Nginx service.${NC}" >&2
    exit 1
fi

echo -e "${GREEN}Nginx setup completed successfully.${NC}"
