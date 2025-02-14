#!/bin/bash

# 1. Ensure KUBECONFIG is correctly set for new sessions.
if ! grep -qxF "export KUBECONFIG=~/.kube/k3s.yaml" ~/.bashrc; then
  echo "export KUBECONFIG=~/.kube/k3s.yaml" >> ~/.bashrc
  echo "Added KUBECONFIG to ~/.bashrc"
fi

# 2. Update /etc/hosts to include the k8sdash mapping.
if ! grep -q "127.0.0.1 k8sdash" /etc/hosts; then
  echo "127.0.0.1 k8sdash" | sudo tee -a /etc/hosts
  echo "Updated /etc/hosts with k8sdash mapping"
fi

# 3. Install the self-signed root certificate into the WSL2 truststore.
CERT_PATH="./cluster-system/cert-manager/certs/tls.crt"
if [ -f "$CERT_PATH" ]; then
  sudo cp "$CERT_PATH" /usr/local/share/ca-certificates/k3s-setup.crt
  sudo update-ca-certificates
  echo "Installed self-signed certificate into CA store"
else
  echo "Certificate not found at $CERT_PATH"
fi