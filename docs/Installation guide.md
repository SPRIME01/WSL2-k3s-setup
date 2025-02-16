# Comprehensive Guide to Installing k3s on WSL2 with External Traefik and Rancher Integration

This guide provides a detailed walkthrough for deploying a k3s Kubernetes cluster on Windows Subsystem for Linux 2 (WSL2) with specific customizations: exclusion of bundled ingress controllers (Traefik/NGINX), integration with an external Traefik instance, Rancher management platform deployment, and Pulumi compatibility. The installation accommodates pre-existing Helm/kubectl tooling, remnant k3s installations, and static IP networking requirements for Docker environments.

## Table of Contents
1. [Prerequisites and WSL2 Configuration](#1-prerequisites-and-wsl2-configuration)
   - [1.1 WSL2 Kernel Preparation](#11-wsl2-kernel-preparation)
   - [1.2 Static IP Assignment and Host Networking](#12-static-ip-assignment-and-host-networking)
2. [k3s Installation with Traefik Exclusion](#2-k3s-installation-with-traefik-exclusion)
   - [2.1 Cleanup Remnant k3s Installations](#21-cleanup-remnant-k3s-installations)
   - [2.2 Install k3s Server Without Bundled Components](#22-install-k3s-server-without-bundled-components)
3. [External Traefik Configuration](#3-external-traefik-configuration)
   - [3.1 Deploy External Traefik Instance](#31-deploy-external-traefik-instance)
   - [3.2 Configure k3s for External Traefik](#32-configure-k3s-for-external-traefik)
4. [Rancher Deployment via Helm](#4-rancher-deployment-via-helm)
   - [4.1 Install Rancher](#41-install-rancher)
   - [4.2 Verify Rancher Accessibility](#42-verify-rancher-accessibility)
5. [Pulumi Integration and Networking](#5-pulumi-integration-and-networking)
   - [5.1 Configure kubeconfig for Windows Host](#51-configure-kubeconfig-for-windows-host)
   - [5.2 Port Forwarding and Firewall Rules](#52-port-forwarding-and-firewall-rules)
6. [Validation and Troubleshooting](#6-validation-and-troubleshooting)
   - [6.1 Cluster Health Checks](#61-cluster-health-checks)
   - [6.2 Traefik-k3s Integration Test](#62-traefik-k3s-integration-test)
7. [Certificate Bootstrapping](#7-certificate-bootstrapping)

---

## 1. Prerequisites and WSL2 Configuration

### 1.1 WSL2 Kernel Preparation
Please refer to the [WSL2 Kernel Compilation Guide](/docs/WSL2-Kernel-Guide.md) for kernal compilation steps.

### 1.2 Static IP Assignment and Host Networking
To ensure consistent networking with Docker’s static IP:

1. **Assign static IP to WSL2**:
   ```bash
   sudo ip addr add <YOUR_STATIC_IP>/24 dev eth0  # Replace <YOUR_STATIC_IP> with your chosen IP
   ```
2. **Configure Windows NAT**:
   Run PowerShell as Administrator:
   ```powershell
   New-NetNat -Name WSL2StaticIP -InternalIPInterfaceAddressPrefix "<YOUR_NETWORK_CIDR>"  # e.g., "192.168.80.0/24"
   ```
   Persist IP assignment across reboots using a WSL2 startup script.

---

## 2. k3s Installation with Traefik Exclusion

### 2.1 Cleanup Remnant k3s Installations
Force-terminate existing k3s processes and purge directories:
```bash
sudo pkill -9 k3s
sudo rm -rf /var/lib/rancher/k3s /etc/rancher/k3s /var/lib/cni/networks/k8s-pod-network
```

### 2.2 Install k3s Server Without Bundled Components
Disable Traefik and servicelb during installation:
```bash
curl -sfL https://get.k3s.io | INSTALL_K3S_EXEC="server --disable traefik --disable servicelb --tls-san <YOUR_STATIC_IP>" sh -
```
- `--tls-san <YOUR_STATIC_IP>`: Adds your chosen static IP to the TLS SAN list for API server access.

---

## 3. External Traefik Configuration

### 3.1 Deploy External Traefik Instance
Launch Traefik in a Docker container on the Windows host (adjust IPs as needed):
```powershell
docker run -d --name traefik -p 80:80 -p 443:443 `
  -v //./pipe/docker_engine://var/run/docker.sock `
  traefik:v2.8 --providers.docker --entrypoints.web.address=:80
```

### 3.2 Configure k3s for External Traefik
Modify the k3s configuration to advertise the API server via your static IP:
```bash
sudo sed -i 's/server:.*/server: https:\/\/<YOUR_STATIC_IP>:6443/' /etc/rancher/k3s/k3s.yaml
```

---

## 4. Rancher Deployment via Helm

### 4.1 Install Rancher
Add Helm repos and deploy Rancher:
```bash
helm repo add rancher-latest https://releases.rancher.com/server-charts/latest
helm install rancher rancher-latest/rancher \
  --namespace cattle-system \
  --set hostname=rancher.yourdomain.com \
  --set replicas=1
```

### 4.2 Verify Rancher Accessibility
After DNS resolution for `rancher.yourdomain.com` points to WSL2’s IP, access Rancher UI at `https://rancher.yourdomain.com`.

---

## 5. Pulumi Integration and Networking

### 5.1 Configure kubeconfig for Windows Host
Copy `k3s.yaml` to Windows and update the cluster server IP:
```bash
cp /etc/rancher/k3s/k3s.yaml /mnt/c/Users/%USERNAME%/.kube/config
```
Edit `C:\Users\%USERNAME%\.kube\config` to replace `127.0.0.1` with `<YOUR_STATIC_IP>`.

### 5.2 Port Forwarding and Firewall Rules
Allow Kubernetes API traffic through Windows Defender Firewall:
```powershell
New-NetFirewallRule -DisplayName "k3s API Server" -Direction Inbound -LocalPort 6443 -Protocol TCP -Action Allow
```

---

## 6. Validation and Troubleshooting

### 6.1 Cluster Health Checks
```bash
kubectl get nodes  # Should show 'Ready' status
kubectl -n cattle-system get pods  # Verify Rancher pods
```

### 6.2 Traefik-k3s Integration Test
Deploy a test ingress resource pointing to Traefik’s external IP:
```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: test-ingress
spec:
  ingressClassName: external-traefik
  rules:
  - host: test.yourdomain.com
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: test-service
            port:
              number: 80
```

---

## 7. Certificate Bootstrapping

For detailed instructions on certificate pre-generation and integration with k3s, please refer to the [Certificate Bootstrapping Guide](Certificate%20bootstraping%20guide.md).

---

This methodology prevents certificate regeneration during cluster operations while maintaining compatibility with Pulumi's static IP requirements. The staged approach reduces Let's Encrypt rate limit risks by decoupling initial issuance from cluster lifecycle events.