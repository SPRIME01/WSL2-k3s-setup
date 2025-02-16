# Windows PowerShell script for NAT & firewall configuration

New-NetNat -Name WSL2StaticIP -InternalIPInterfaceAddressPrefix "192.168.80.0/24"
New-NetFirewallRule -DisplayName "k3s API Server" -Direction Inbound -LocalPort 6443 -Protocol TCP -Action Allow
