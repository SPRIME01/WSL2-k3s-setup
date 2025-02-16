#!/bin/bash
set -euo pipefail

# Ensure the script is run as root
if [[ $EUID -ne 0 ]]; then
  echo "This script must be run as root."
  exit 1
fi

echo "Starting uninstallation of k3s and related components..."

# Uninstall k3s if the built-in uninstall script exists
if [ -f /usr/local/bin/k3s-uninstall.sh ]; then
  echo "Running k3s-uninstall.sh..."
  /usr/local/bin/k3s-uninstall.sh
else
  echo "k3s-uninstall.sh not found; skipping k3s uninstall."
fi

# Remove residual directories
echo "Removing residual directories..."
rm -rf /var/lib/rancher/k3s \
       /etc/rancher/k3s \
       /var/lib/cni/networks/k8s-pod-network

# Remove Traefik Docker container if exists
if command -v docker &> /dev/null; then
  if docker ps -a --format '{{.Names}}' | grep -q "^traefik$"; then
    echo "Stopping and removing Traefik container..."
    docker stop traefik
    docker rm traefik
  else
    echo "Traefik container not found; skipping container removal."
  fi
fi

echo "Uninstallation complete."
