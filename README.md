# About

This project contains a set of scripts designed to automate the setup of a deployment environment on AlmaLinux. The scripts handle the installation of essential tools such as Node.js, PM2, PNPM, and NVM, along with their configurations.

## Project Structure

- **scripts/**: Contains the main scripts for setting up the environment.
  - **01.init.base.sh**: Initial setup script for basic configurations.
  - **02.init.node.sh**: Installs Node.js, PNPM.
  - **03.init.pm2.sh**: Installs PM2.
  - **04.init.nginx.sh**: Installs nginx.
  - **05.init.docker.sh**: Installs docker.
  - **utils/**: Contains utility functions for reuse across scripts.
    - **helpers.sh**: Utility functions for error handling and logging.
  
- **configs/**: Contains configuration files for the installed tools.
  - **home**: Configuration settings in the user home dir.
  - **ssh**: Configuration settings for ssh.

- **README.md**: Documentation for the project.

- **install.sh**: Main installation script that orchestrates the execution of the other scripts.

## Prerequisites

Ensure that you have the following installed on your AlmaLinux system before running the scripts:

- A compatible version of AlmaLinux.
- Sufficient permissions to install software and modify system configurations.

### Install `curl`, `wget` and `git`

```sh
# Update the system
sudo dnf update -y
# Install necessary dependencies
sudo dnf install -y curl wget git
```

### Add the server's ssh key to github

Generate the key,

```sh
# 在服务器上生成密钥（默认保存到 ~/.ssh/id_ed25519）
ssh-keygen -t ed25519 -C "your_email@example.com"
# 直接按回车保持默认路径，空密码（安全场景下）
```

Check the pub key,

```sh
cat ~/.ssh/id_ed25519.pub
# 输出示例：ssh-ed25519 AAAAB3NzaC1yc2E... your_email@example.com
```

Add the key to github,

- Visit：https://github.com/settings/keys
- Click `New SSH Key`, paste the pub key's content
- If you only need to access a single repository, you can add it as a Deploy Key in the repository settings:
  - Repository homepage → Settings → Deploy keys → Add deploy key


## Usage

1. Clone the repository to your local machine.
2. Navigate to the project directory.
3. Run the installation script:

   ```bash
   bash install.sh
   ```

This will execute the scripts in the correct order to set up your development environment.

## License

This project is licensed under the MIT License. See the LICENSE file for more details.