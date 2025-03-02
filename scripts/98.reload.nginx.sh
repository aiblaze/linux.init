#!/bin/bash
#
# Script to reload Nginx after SSL certificate updates
# Typically run after certificate renewal

# Log function for better output
log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1"
}

# Check if running as root
if [[ $EUID -ne 0 ]]; then
   log "Error: This script must be run as root"
   exit 1
fi

# Check if nginx is installed
if ! command -v nginx &> /dev/null; then
    log "Error: nginx is not installed or not in PATH"
    exit 1
fi

# Test nginx configuration
log "Testing nginx configuration..."
if ! nginx -t &> /dev/null; then
    log "Error: nginx configuration test failed"
    nginx -t  # Run again to show the actual error
    exit 1
fi

# Check if nginx is running and reload/restart as needed
if systemctl is-active --quiet nginx; then
    log "Reloading nginx to apply new SSL certificates..."
    if systemctl reload nginx; then
        log "Success: nginx successfully reloaded with updated SSL certificates"
    else
        log "Warning: Reload failed, attempting restart..."
        if systemctl restart nginx; then
            log "Success: nginx successfully restarted with updated SSL certificates"
        else
            log "Error: Failed to restart nginx"
            exit 1
        fi
    fi
else
    log "Warning: nginx is not running. Starting nginx..."
    if systemctl start nginx; then
        log "Success: nginx started with updated SSL certificates"
    else
        log "Error: Failed to start nginx"
        exit 1
    fi
fi

exit 0