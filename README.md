# AlmaLinux Environment Setup

This project provides an automated setup for a deployment environment on AlmaLinux. The scripts install and configure essential development tools and services.

## Overview

This toolset automates the installation and configuration of:

- Node.js, npm, PNPM, and NVM
- PM2 process manager
- Nginx web server with optimized configuration (based on H5BP)
- Docker and Docker Compose
- System configurations (SSH timeout settings, shell configurations)

## Prerequisites

- AlmaLinux 8 or 9
- Root access or sudo privileges
- Internet connection

## Quick Start

### Install `curl`, `wget` and `git`

```sh
# Update the system
sudo dnf update -y
# Install necessary dependencies
sudo dnf install -y curl wget git
```

### Clone this repository and run the installation script

```bash
git clone https://github.com/your-username/almalinux.init.git
cd almalinux.init
sudo bash install.sh
```
Follow the prompts during installation.

## Customizing Docker Registry Mirror (Highly recommended)

You can specify a custom Docker registry mirror by setting the `DOCKER_REGISTRY_MIRROR` environment variable:

```bash
# Using a custom Docker registry mirror
sudo DOCKER_REGISTRY_MIRROR=https://your-registry-mirror.com bash install.sh

# Or pass it directly to the Docker script
sudo DOCKER_REGISTRY_MIRROR=https://your-registry-mirror.com bash scripts/05.init.docker.sh
```

## Installation Steps

The installation process includes the following steps:

1. Base Setup (01.init.base.sh)

  - System updates
  - Installation of essential utilities (curl, wget, git)

2. Node.js Environment (02.init.node.sh)

  - Node.js installation
  - PNPM package manager
  - NVM (Node Version Manager)

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
  - npm registry configuration

## Configuration Details

### Docker Registry Mirror

The Docker setup configures a registry mirror to speed up image downloads:

- Default mirror: `https://n3zlurtb.mirror.aliyuncs.com` (Alibaba Cloud)
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

- Modifying configuration files in the configs directory
- Editing the individual scripts to change versions or options
- Adding new scripts to the installation sequence (update `install.sh`)
- Setting environment variables (such as `DOCKER_REGISTRY_MIRROR`) to customize behaviors

## Troubleshooting

### Common Issues

1. SSH configuration not applying

  - Ensure the SSH service was reloaded: `systemctl status sshd`
  - Check for syntax errors: `sshd -t`

2. Node.js or npm errors

  - Check installed versions: `node -v && npm -v`
  - Try reinstalling: `bash scripts/02.init.node.sh`

3. Nginx failing to start

  - Check configuration: `nginx -t`
  - View logs: `journalctl -u nginx`

4. Docker registry mirror issues

  - Verify your mirror configuration: `cat /etc/docker/daemon.json`
  - Test connectivity: `curl -I https://your-registry-mirror.com/v2/`
  - Restart Docker after changes: `systemctl restart docker`

### Logs

Installation logs are saved to `/var/log/almalinux.init/`.

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## License

This project is licensed under the MIT License - see the LICENSE file for details.
