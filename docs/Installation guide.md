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
7. [Certificate Pre-Generation with Docker-Compose](#7-certificate-pre-generation-with-docker-compose)
   - [7.1 Docker-Compose for Certificate Pre-Generation](#71-docker-compose-for-certificate-pre-generation)
   - [7.2 Modified Installation Sequence](#72-modified-installation-sequence)
   - [7.3 DNS Challenge Alternative](#73-dns-challenge-alternative)
   - [7.4 Validation](#74-validation)

---

## 1. Prerequisites and WSL2 Configuration

### 1.1 WSL2 Kernel Preparation
k3s requires kernel support for Kubernetes networking components. Microsoft’s default WSL2 kernel lacks critical modules (e.g., `CONFIG_BRIDGE_NETFILTER`, `CONFIG_VXLAN`). Compile a custom kernel:

1. **Install dependencies**:
   ```bash
   sudo apt update && sudo apt install build-essential flex bison libssl-dev libelf-dev
   ```
2. **Download WSL2 kernel source**:
   ```bash
   git clone https://github.com/microsoft/WSL2-Linux-Kernel
   cd WSL2-Linux-Kernel
   ```
3. **Configure kernel**:
   ```bash
   cp Microsoft/config-wsl .config
   cat >> .config << EOF
   CONFIG_BRIDGE_NETFILTER=y
   CONFIG_NETFILTER_XT_MATCH_COMMENT=y
   CONFIG_NETFILTER_XT_MATCH_MULTIPORT=y
   CONFIG_NETFILTER_XT_MATCH_OWNER=y
   CONFIG_NETFILTER_XT_MATCH_PHYSDEV=y
   CONFIG_VXLAN=y
   CONFIG_GENEVE=y
   EOF
   make oldconfig && make -j $(nproc)
   ```
4. **Replace WSL2 kernel**:
   Copy `arch/x86/boot/bzImage` to `C:\Windows\System32\lxss\tools\kernel` after shutting down WSL (`wsl --shutdown`).

### 1.2 Static IP Assignment and Host Networking
To ensure consistent networking with Docker’s static IP:

1. **Assign static IP to WSL2**:
   ```bash
   sudo ip addr add 192.168.80.2/24 dev eth0  # Replace with desired IP
   ```
2. **Configure Windows NAT**:
   Run PowerShell as Administrator:
   ```powershell
   New-NetNat -Name WSL2StaticIP -InternalIPInterfaceAddressPrefix "192.168.80.0/24"
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
curl -sfL https://get.k3s.io | INSTALL_K3S_EXEC="server --disable traefik --disable servicelb --tls-san 192.168.80.2" sh -
```
- `--tls-san 192.168.80.2`: Adds WSL2’s static IP to TLS SAN list for API server access.

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
Modify k3s service to advertise API server via WSL2’s IP:
```bash
sudo sed -i 's/server:.*/server: https:\/\/192.168.80.2:6443/' /etc/rancher/k3s/k3s.yaml
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
Copy `k3s.yaml` to Windows and update server IP:
```bash
cp /etc/rancher/k3s/k3s.yaml /mnt/c/Users/%USERNAME%/.kube/config
```
Edit `C:\Users\%USERNAME%\.kube\config` to replace `127.0.0.1` with `192.168.80.2`.

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

## 7. Certificate Pre-Generation with Docker-Compose

### 7.1 Docker-Compose for Certificate Pre-Generation
Create `prestage-traefik.yaml` on the Windows host:
```yaml
version: "3.3"
services:
  traefik-bootstrap:
    image: "traefik:v3.3"
    container_name: "traefik-cert-generator"
    command:
      - "--providers.docker=true"
      - "--providers.docker.exposedbydefault=false"
      - "--entryPoints.websecure.address=:443"
      - "--certificatesresolvers.k3sresolver.acme.tlschallenge=true"
      - "--certificatesresolvers.k3sresolver.acme.email=admin@yourdomain.com"
      - "--certificatesresolvers.k3sresolver.acme.storage=/letsencrypt/k3s-acme.json"
    ports:
      - "443:443"
    volumes:
      - "c:/k3s-cert-volume:/letsencrypt"
      - "/var/run/docker.sock:/var/run/docker.sock:ro"
    networks:
      - k3s-preflight

  cert-trigger:
    image: alpine:latest
    command: ["sh", "-c", "echo 'Certificate generation triggered'"]
    labels:
      - "traefik.enable=true"
      - "traefik.http.routers.cert-issuer.rule=Host(`rancher.yourdomain.com`)"
      - "traefik.http.routers.cert-issuer.entrypoints=websecure"
      - "traefik.http.routers.cert-issuer.tls.certresolver=k3sresolver"
    networks:
      - k3s-preflight

networks:
  k3s-preflight:
    driver: bridge
    ipam:
      config:
        - subnet: 192.168.90.0/24
```

### 7.2 Modified Installation Sequence

#### Step 1: Generate Certificates
```powershell
# Windows host
docker-compose -f prestage-traefik.yaml up -d

# Verify ACME issuance
curl -vk https://rancher.yourdomain.com --resolve rancher.yourdomain.com:443:192.168.90.2
```

#### Step 2: Install k3s with Certificate Preload
```bash
# WSL2 terminal
sudo mkdir -p /etc/rancher/k3s/certs
sudo cp /mnt/c/k3s-cert-volume/k3s-acme.json /etc/rancher/k3s/certs/

INSTALL_K3S_EXEC="server
  --disable traefik
  --tls-san rancher.yourdomain.com
  --kubelet-arg=volume-plugin-dir=/etc/rancher/k3s/certs"

curl -sfL https://get.k3s.io | sh -
```

#### Step 3: Cluster Traefik Configuration
Create `traefik-helm-values.yaml`:
```yaml
additionalArguments:
  - "--certificatesresolvers.k3sresolver.acme.tlschallenge=true"
  - "--certificatesresolvers.k3sresolver.acme.email=admin@yourdomain.com"
  - "--certificatesresolvers.k3sresolver.acme.storage=/data/k3s-acme.json"

persistence:
  existingClaim: "cert-volume"

volumes:
  - name: cert-volume
    hostPath:
      path: /etc/rancher/k3s/certs
      type: Directory
```

Deploy Traefik:
```bash
helm upgrade --install traefik traefik/traefik -f traefik-helm-values.yaml
```

#### Step 4: Teardown Bootstrap
```powershell
docker-compose -f prestage-traefik.yaml down
```

### 7.3 DNS Challenge Alternative
For non-public hosts, modify `prestage-traefik.yaml` with DNS credentials:
```yaml
# traefik-bootstrap service additions
command:
  - "--certificatesresolvers.k3sresolver.acme.dnschallenge=true"
  - "--certificatesresolvers.k3sresolver.acme.dnschallenge.provider=cloudflare"

environment:
  - CF_API_EMAIL=${CF_EMAIL}
  - CF_API_KEY=${CF_API_KEY}
```

### 7.4 Validation
Confirm certificate continuity:
```bash
kubectl exec deploy/traefik -- ls /data
# Should show k3s-acme.json with timestamp matching pre-stage
```

---

This methodology prevents certificate regeneration during cluster operations while maintaining compatibility with Pulumi's static IP requirements. The staged approach reduces Let's Encrypt rate limit risks by decoupling initial issuance from cluster lifecycle events.