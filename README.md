# Linux Environment Setup

This project provides an automated setup for a deployment environment on various Linux distributions. The scripts install and configure essential development tools and services.

## Overview

This toolset automates the installation and configuration of:

- Node.js, npm, PNPM, and NVM
- PM2 process manager
- Nginx web server with optimized configuration (based on H5BP)
- Docker and Docker Compose
- System configurations (SSH timeout settings, shell configurations)

## Prerequisites

- AlmaLinux 8 or 9, CentOS, Ubuntu, or other Linux distributions
- Root access or sudo privileges
- Internet connection

## Quick Start

### Install `curl`, `wget` and `git`

```sh
# Update the system
sudo dnf update -y   # For RHEL-based systems (AlmaLinux, CentOS)
# or
sudo apt update -y   # For Debian-based systems (Ubuntu)

# Install necessary dependencies
sudo dnf install -y curl wget git   # For RHEL-based systems
# or
sudo apt install -y curl wget git   # For Debian-based systems
```

### Clone this repository and run the installation script

```bash
git clone https://github.com/aiblaze/linux.init.git
cd linux.init
sudo bash install.sh
```
Follow the prompts during installation.

### Non-Interactive Mode (for Automation)

For automated installations or CI/CD pipelines, you can use non-interactive mode:

```bash
# Set NON_INTERACTIVE=true to skip all prompts
export NON_INTERACTIVE=true

# Configure all necessary variables
export NODEJS_VERSION="23.x"
export DOCKER_REGISTRY_MIRROR="https://registry-1.docker.io"
export PM2_VERSION="latest"

# Run the installation with environment variables preserved
sudo -E bash install.sh
```

#### Using with GitHub Actions

You can use this script in GitHub Actions workflows for automated server setup:

```yaml
name: Server Setup

on:
  workflow_dispatch:
    inputs:
      server_ip:
        description: 'Server IP address'
        required: true
      ssh_key:
        description: 'SSH private key (secret)'
        required: true

jobs:
  setup:
    runs-on: ubuntu-latest
    steps:
      - name: Checkout code
        uses: actions/checkout@v3
        
      - name: Setup SSH
        uses: webfactory/ssh-agent@v0.7.0
        with:
          ssh-private-key: ${{ secrets.SSH_PRIVATE_KEY }}
          
      - name: Deploy and run setup script
        run: |
          scp -o StrictHostKeyChecking=no -r ./* root@${{ github.event.inputs.server_ip }}:/tmp/linux.init/
          ssh -o StrictHostKeyChecking=no root@${{ github.event.inputs.server_ip }} "cd /tmp/linux.init && NON_INTERACTIVE=true NODEJS_VERSION=23.x DOCKER_REGISTRY_MIRROR=https://registry-1.docker.io bash install.sh"
```

## Configuration Variables

You can customize the installation by setting environment variables before running the scripts:

### Node.js Configuration

```bash
# Specify Node.js version and installation source
export NODEJS_VERSION="23.x"  # Default is 23.x
export NODEJS_SOURCE="https://rpm.nodesource.com/setup_${NODEJS_VERSION}"  # For RPM-based systems
export NODEJS_DEB_SOURCE="https://deb.nodesource.com/setup_${NODEJS_VERSION}"  # For Debian-based systems

# Run the installation
sudo -E bash install.sh  # -E preserves environment variables
```

### NVM Configuration

```bash
# Specify NVM version and installation directory
export NVM_VERSION="0.40.1"  # Default is 0.40.1
export NVM_DIR="$HOME/.nvm"  # Default installation directory
export NVM_INSTALL_URL="https://raw.githubusercontent.com/nvm-sh/nvm/v${NVM_VERSION}/install.sh"

# Run the installation
sudo -E bash install.sh
```

### Docker Registry Mirror

You can specify a custom Docker registry mirror:

```bash
# Using a custom Docker registry mirror
export DOCKER_REGISTRY_MIRROR="https://your-registry-mirror.com"
sudo -E bash install.sh

# Or pass it directly to the Docker script
sudo DOCKER_REGISTRY_MIRROR="https://your-registry-mirror.com" bash scripts/05.init.docker.sh
```

## Installation Steps

The installation process includes the following steps:

1. Base Setup (01.init.base.sh)

  - System updates
  - Installation of essential utilities (curl, wget, git)

2. Node.js Environment (02.init.node.sh)

  - Node.js installation (configurable via `NODEJS_VERSION` and `NODEJS_SOURCE`)
  - PNPM package manager (configurable via `PNPM_VERSION`)
  - NVM (Node Version Manager) (configurable via `NVM_VERSION` and `NVM_DIR`)

3. PM2 Process Manager (03.init.pm2.sh)

  - PM2 installation
  - Startup configuration

4. Nginx Web Server (04.init.nginx.sh)

  - Nginx installation
  - H5BP optimized configuration
  - Directory setup

5. Docker (05.init.docker.sh)

  - Docker CE installation
  - Docker Compose installation
  - Registry mirror configuration for faster downloads
    - Default mirror: https://n3zlurtb.mirror.aliyuncs.com
    - Can be customized via `DOCKER_REGISTRY_MIRROR` environment variable

6. Configuration Files (99.init.conf.sh)

  - SSH timeout settings (prevents idle disconnections)
  - Shell configurations (.bashrc)
  - npm registry configuration (configurable via `NPM_REGISTRY`)

## Configuration Details

### Docker Registry Mirror

The Docker setup configures a registry mirror to speed up image downloads:

- Default mirror: `https://n3zlurtb.mirror.aliyuncs.com`
- You can customize this by:

  - Setting the `DOCKER_REGISTRY_MIRROR` environment variable
  - Passing the mirror URL as the first argument to the script
  - Responding to the interactive prompt during installation
  - The configuration is stored in `/etc/docker/daemon.json`

### SSH Settings

The SSH timeout configuration in `timeout.conf` sets:

- `ClientAliveInterval 300`: Server sends a keep-alive request every 5 minutes
- `ClientAliveCountMax 3`: Connection closes after 3 failed keep-alive responses (15 minutes total)

### Nginx Configuration

The Nginx setup uses the H5BP configuration for best practices:

- Optimized for performance
- SSL security settings
- Compression and caching settings

Refer to [readme.nginx.md](./configs/home/readme.nginx.md) for usage instructions.

## Customization

You can customize the installation by:

- Setting environment variables as described in the [Configuration Variables](#configuration-variables) section
- Modifying configuration files in the configs directory
- Editing the individual scripts to change versions or options
- Adding new scripts to the installation sequence (update `install.sh`)

### Available Configuration Variables

| Variable | Description | Default Value |
|----------|-------------|---------------|
| `NON_INTERACTIVE` | Run in non-interactive mode (no prompts) | `false` |
| `NODEJS_VERSION` | Node.js version to install | `23.x` |
| `NODEJS_SOURCE` | URL for Node.js installation script (RPM) | `https://rpm.nodesource.com/setup_23.x` |
| `NODEJS_DEB_SOURCE` | URL for Node.js installation script (DEB) | `https://deb.nodesource.com/setup_23.x` |
| `NVM_VERSION` | NVM version to install | `0.40.1` |
| `NVM_DIR` | NVM installation directory | `$HOME/.nvm` |
| `NVM_INSTALL_URL` | URL for NVM installation script | Based on `NVM_VERSION` |
| `PNPM_VERSION` | PNPM version to install | `latest` |
| `PM2_VERSION` | PM2 version to install | `latest` |
| `DOCKER_REGISTRY_MIRROR` | Docker registry mirror URL | `https://n3zlurtb.mirror.aliyuncs.com` |
| `DOCKER_LOG_MAX_SIZE` | Maximum size of Docker container logs | `100m` |
| `DOCKER_LOG_MAX_FILE` | Maximum number of Docker log files | `3` |
| `DOCKER_STORAGE_DRIVER` | Docker storage driver | `overlay2` |
| `NPM_REGISTRY` | NPM registry URL | Default npm registry |

## Troubleshooting

### Common Issues

1. SSH configuration not applying

  - Ensure the SSH service was reloaded: `systemctl status sshd`
  - Check for syntax errors: `sshd -t`

2. Node.js or npm errors

  - Check installed versions: `node -v && npm -v`
  - Try reinstalling with a different version: `NODEJS_VERSION=23.x bash scripts/02.init.node.sh`

3. Nginx failing to start

  - Check configuration: `nginx -t`
  - View logs: `journalctl -u nginx`

4. Docker registry mirror issues

  - Verify your mirror configuration: `cat /etc/docker/daemon.json`
  - Test connectivity: `curl -I https://your-registry-mirror.com/v2/`
  - Restart Docker after changes: `systemctl restart docker`

### Logs

Installation logs are saved to `/var/log/linux.init/`.

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## License

This project is licensed under the MIT License - see the LICENSE file for details.
