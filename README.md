# Modded k3s Setup

A project for deploying k3s on WSL2 with external Traefik integration, Rancher management, and Pulumi compatibility.

## Overview
This project provides a modular and customizable setup for k3s on Windows Subsystem for Linux 2 (WSL2). It excludes the default Traefik and servicelb, integrates with an external Traefik instance, and includes setup instructions for Rancher and Pulumi integration.

## Getting Started
First, clone the repository:
```bash
git clone https://github.com/SPRIME01/WSL2-k3s-setup.git
cd WSL2-k3s-setup
```


## Features
- Custom k3s installation with Traefik exclusion
- External Traefik configuration with dynamic certificate management using Docker Compose
- Rancher deployment via Helm for Kubernetes management
- Pulumi integration with static IP setup for stable networking

## Prerequisites
- Windows 10/11 with WSL2 enabled
- Docker Desktop installed and configured
- Basic knowledge of Kubernetes, Helm, and Docker
- Existing Helm/kubectl tooling

## Installation
1. Review the complete [Installation Guide](docs/Installation%20guide.md) for step-by-step instructions.
2. Setup prerequisites including custom WSL2 kernel configuration and static IP assignment.
3. Execute the provided shell scripts and commands in the guide.
4. Update configuration values marked with angle brackets (e.g., `<YOUR_STATIC_IP>`, `<YOUR_RANCHER_HOSTNAME>`) to match your environment.

## Usage
- Follow the instructions in the Installation Guide to deploy the cluster.
- Use kubectl to verify the cluster status and interact with the deployed applications.
- Access Rancher through the configured hostname once DNS is properly set.

## Uninstallation
To remove k3s and related components, run the uninstall script as root:
```bash
sudo ./uninstall.sh
```
This script will:
- Run the built-in k3s uninstall (if available).
- Remove residual k3s directories.
- Stop and remove the Traefik Docker container (if it exists).

## Contributing
Contributions are welcome. Please follow these steps:
- Fork the repository.
- Create a feature or bugfix branch.
- Submit a Pull Request detailing your changes.

## License
Distributed under the MIT License. See `LICENSE` for more information.

