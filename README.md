# WSL2 k3s-setup

An easy-to-use project to automatically set up a K3s-based Kubernetes environment for local development. It is made for WSL2 (Windows Subsystem for Linux 2) but supports native Linux configurations as well – no more need for Docker Desktop on Windows, making it especially ideal for corporate environments.

---

## Table of Contents

1. [Overview](#overview)
2. [Quick Start Guide](#quick-start-guide)
3. [Requirements](#requirements)
4. [Installation Steps](#installation-steps)
5. [Post-Installation and Windows Setup Scripts](#post-installation-and-windows-setup-scripts)
6. [Detailed Script Breakdown](#detailed-script-breakdown)
7. [Using External Traefik with K3s Ingress](#using-external-traefik-with-k3s-ingress)
8. [Stopping, Restarting & Uninstalling](#stopping-restarting--uninstalling)

---

## Overview

This project automatically sets up a minimal K3s cluster with essential services including:
- Kubernetes Metrics Server
- Certificate Manager (with a self-signed root certificate)
- Kubernetes Dashboard

On Windows (via WSL2) it also configures K3s to work with an external Traefik instance running on the host.

Tested environments include:
- Ubuntu Linux 22.04
- Debian 11
- Ubuntu Linux 22.04 on WSL2 (Windows 10/11)
- Debian 11 on WSL2 (Windows 10/11)

---

## Quick Start Guide

### Clone and Run

```bash
git clone https://github.com/groundhog2k/k3s-setup.git
cd k3s-setup
./k3s-setup.sh
```

After running, install the self-signed root certificate found at:
```
./cluster-system/cert-manager/certs/tls.crt
```
into your browser or computer’s truststore.

Access the Kubernetes Dashboard by opening:
[https://k8sdash](https://k8sdash) in your browser.

### Windows Specific Instructions

1. Edit the hosts file (typically located at `C:\Windows\system32\drivers\etc\hosts`) and add:
   ```
   127.0.0.1 k8sdash
   ```
2. For Linux/WSL2, update your KUBECONFIG:
   ```bash
   export KUBECONFIG=~/.kube/k3s.yaml
   ```

---

## Requirements

- Internet access (direct or via a configured HTTP/HTTPS proxy)
- WSL2 distros must have [systemd support enabled](https://devblogs.microsoft.com/commandline/systemd-support-is-now-available-in-wsl/#set-the-systemd-flag-set-in-your-wsl-distro-settings)
- `sudo` privileges
- Installed `curl` and [Helm](https://helm.sh/docs/intro/install/)

---

## Installation Steps

1. **Clone the repository and run the setup script:**
   ```bash
   git clone https://github.com/groundhog2k/k3s-setup.git
   cd k3s-setup
   ./k3s-setup.sh
   ```
2. **Certificate Installation:**
   - After installation, install the generated self-signed root certificate (`./cluster-system/cert-manager/certs/tls.crt`) into your local system truststore.

3. **Access Dashboard:**
   - Open [https://k8sdash](https://k8sdash) in your browser.

4. **Windows Host:**
   - Edit the Windows hosts file to add the mapping for `k8sdash`.

5. **KUBECONFIG Configuration (Linux/WSL2):**
   - Run:
     ```bash
     export KUBECONFIG=~/.kube/k3s.yaml
     ```

---

## Post-Installation and Windows Setup Scripts

This project provides additional scripts for post-install configuration to ensure that your environment is correctly set up after installing K3s.

### WSL2 Post-Installation Script

For Linux or WSL2 users, the `wsl2-post-install-script.sh` performs the following tasks:
- **KUBECONFIG Setup:** Adds `export KUBECONFIG=~/.kube/k3s.yaml` to your `~/.bashrc` so that new sessions have the correct KUBECONFIG environment variable set.
- **Hosts File Update:** Updates `/etc/hosts` with the entry `127.0.0.1 k8sdash` to simplify access to the Kubernetes Dashboard.
- **Certificate Installation:** Installs the self-signed certificate (`./cluster-system/cert-manager/certs/tls.crt`) into your system’s CA store.

**Usage:**
Run the script from the project root:
```bash
./wsl2-post-install-script.sh
```

### Windows Post-Installation Script

For Windows users, the `windows-post-install-script.ps1` does the following:

- **KUBECONFIG Configuration:** Sets the KUBECONFIG environment variable persistently for the current user.
- **Hosts File Update:** Adds the `127.0.0.1 k8sdash` entry to your Windows hosts file.
- **Certificate Installation:** Imports the self-signed certificate into the Windows Trusted Root store.  
  _Note: Running this script may require administrative privileges._

**Usage:**
Open PowerShell as Administrator and execute:
```powershell
.\windows-post-install-script.ps1
```

### Windows Uninstallation Script

If there is a need to remove the modifications made by the Windows post-install script, you can use the `windows-uninstall.ps1` script. It will:

- Remove the KUBECONFIG environment variable from the current user.
- Remove the `127.0.0.1 k8sdash` entry from your hosts file.
- Remove the self-signed certificate from the Trusted Root store (ensure the certificate is correctly identified).

**Usage:**
Open PowerShell as Administrator and execute:
```powershell
.\windows-uninstall.ps1
```

---

## Detailed Script Breakdown

The main script `k3s-setup.sh` builds upon several sub-scripts:

1. **k3s/prepare-k3s.sh**
   - Copies `crictl.yaml` to `/etc` to set containerd as the primary container runtime.
   - Downloads and starts a clean K3s cluster (without Helm controller, Traefik, or Metrics Server).

2. **cluster-system/cluster-setup.sh**
   - Creates a Kubernetes namespace `cluster-system` to house additional components.
   - **Sub-scripts include:**
     - **metrics-server/install.sh:** Installs Kubernetes Metrics Server using the official Helm chart.
     - **cert-manager/install.sh:** Generates a self-signed root certificate (if not already present) and deploys the Jetstack Cert-Manager.
     - **k8s-dashboard/install.sh:** Installs the Kubernetes Dashboard via Helm.  
       _Note: Make sure the self-signed root certificate is trusted by your system._

3. **Traefik Configuration Check**
   - The main `k3s-setup.sh` script checks for Traefik running on the Windows host.  
     If detected, it configures K3s to use external Traefik. Otherwise, K3s waits until Traefik becomes available.

---

## Using External Traefik with K3s Ingress

By default, in the provided `docker-compose-traefik.yml` file, the flag for Kubernetes Ingress is commented out to prevent startup errors when the Kubernetes API is unavailable.

Example configuration:
```yaml
command:
  - --api.insecure=true
  #- --providers.kubernetesingress
  - --entrypoints.web.address=:80
  - --entrypoints.websecure.address=:443
```

### Why Comment Out the Flag?
When starting Traefik via Docker Compose before K3s is installed, the Kubernetes API endpoint isn’t available. Commenting out the `--providers.kubernetesingress` flag prevents errors like:
```
time="2025-02-14T21:00:19Z" level=error msg="Cannot start the provider *ingress.Provider: endpoint missing for external cluster client"
```

### Steps to Enable Ingress with K3s
1. **Edit `docker-compose-traefik.yml`:**
   - Uncomment the `--providers.kubernetesingress` line.
2. **Restart Traefik:**
   - Run:
     ```bash
     docker-compose down
     docker-compose up -d traefik
     ```
This enables Traefik to detect ingress objects and integrate with your K3s cluster.

---

## Stopping, Restarting & Uninstalling

### To Stop K3s
```bash
k3s-killall.sh
```

### To Restart K3s
```bash
sudo service k3s start
```

### To Uninstall K3s and All Components
```bash
k3s-uninstall.sh
```

Enjoy your Kubernetes environment with all the essential tools ready for development!
