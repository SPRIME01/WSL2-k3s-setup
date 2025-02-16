# Certificate Bootstrapping with Docker-Compose

This guide explains how to bootstrap certificates using Docker-Compose for the k3s setup.

## Step 1: Generate Certificates
Run the bootstrap container on the Windows host:
```powershell
docker-compose -f prestage-traefik.yaml up -d
```
Verify ACME issuance:
```bash
curl -vk https://<YOUR_RANCHER_HOSTNAME> --resolve <YOUR_RANCHER_HOSTNAME>:443:<DOCKER_CERT_IP>
```
Replace `<DOCKER_CERT_IP>` with the IP address assigned to the Docker network for certificate generation.

## Step 2: Install k3s with Certificate Preload
On the WSL2 terminal, copy the certificate JSON and install k3s:
```bash
sudo mkdir -p /etc/rancher/k3s/certs
sudo cp /mnt/c/k3s-cert-volume/k3s-acme.json /etc/rancher/k3s/certs/
INSTALL_K3S_EXEC="server --disable traefik --tls-san <YOUR_RANCHER_HOSTNAME> --kubelet-arg=volume-plugin-dir=/etc/rancher/k3s/certs" curl -sfL https://get.k3s.io | sh -
```

## Step 3: Cluster Traefik Configuration
Create or update the Traefik Helm values file (e.g., traefik-helm-values.yaml):
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
Deploy Traefik using:
```bash
helm upgrade --install traefik traefik/traefik -f traefik-helm-values.yaml
```

## Step 4: Teardown Bootstrap
On the Windows host, remove the bootstrap containers:
```powershell
docker-compose -f prestage-traefik.yaml down
```

## Optional: DNS Challenge Alternative
If using DNS challenge, add the following to the prestage-traefik.yaml under the traefik-bootstrap service:
```yaml
command:
  - "--certificatesresolvers.k3sresolver.acme.dnschallenge=true"
  - "--certificatesresolvers.k3sresolver.acme.dnschallenge.provider=cloudflare"
environment:
  - CF_API_EMAIL=${CF_EMAIL}
  - CF_API_KEY=${CF_API_KEY}
