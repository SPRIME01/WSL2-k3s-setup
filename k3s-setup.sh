#!/bin/bash
# Bootstrap a K3s based Kubernetes setup with metrics, ingress, cert-manager and K8s dashboard
## 1. Bootstrap K3s
cd k3s
./prepare-k3s.sh

# Wait until the k3s API server is up before moving on
echo "Waiting for K3s API server to become reachable..."
until kubectl get nodes --kubeconfig=~/.kube/k3s.yaml >/dev/null 2>&1; do
    echo "Waiting for API server..."
    sleep 5
done
echo "K3s API server is up!"

## 2. Prepare cluster services
cd ../cluster-system
./cluster-setup.sh

## 3. Check if Traefik is running on the Windows host
if nc -zv $(hostname).local 80 2>&1 | grep -q succeeded; then
  echo "Traefik is running on the Windows host"
  echo "K3s will be configured to use external Traefik"
else
  echo "Traefik is not running on the Windows host"
  echo "K3s will be configured to use external Traefik once it is available"
fi

## 4. Log the version of the install and ask the user whether to continue
if nc -zv $(hostname).local 80 2>&1 | grep -q succeeded; then
  echo "Traefik is running on the Windows host"
  echo "K3s will be configured to use external Traefik"
  read -p "Do you want to continue with this setup? (y/n): " choice
  if [[ "$choice" != "y" ]]; then
    echo "Setup aborted by user"
    exit 1
  fi
else
  echo "Traefik is not running on the Windows host"
  echo "K3s will be configured to use external Traefik once it is available"
  read -p "Do you want to continue with this setup? (y/n): " choice
  if [[ "$choice" != "y" ]]; then
    echo "Setup aborted by user"
    exit 1
  fi
fi

echo "*** Finished! Enjoy your local K8s environment. ***"
