# WSL2 Kernel Compilation Guide

This document provides instructions for compiling a custom WSL2 kernel with the necessary modules for k3s.

## Steps

1. Install Dependencies  
   Update package repositories and install the required tools and libraries.
   ```bash
   sudo apt update
   sudo apt install build-essential flex bison libssl-dev libelf-dev -y
   ```

2. Download WSL2 Kernel Source  
   Clone Microsoft’s official WSL2 kernel repository.
   ```bash
   git clone https://github.com/microsoft/WSL2-Linux-Kernel.git
   cd WSL2-Linux-Kernel
   ```

3. Configure and Compile the Kernel  
   a. Copy the default configuration:
   ```bash
   cp Microsoft/config-wsl .config
   ```
   b. Append necessary configuration options:
   ```bash
   cat >> .config << EOF
   CONFIG_BRIDGE_NETFILTER=y
   CONFIG_NETFILTER_XT_MATCH_COMMENT=y
   CONFIG_NETFILTER_XT_MATCH_MULTIPORT=y
   CONFIG_NETFILTER_XT_MATCH_OWNER=y
   CONFIG_NETFILTER_XT_MATCH_PHYSDEV=y
   CONFIG_VXLAN=y
   CONFIG_GENEVE=y
   EOF
   ```
   c. Update and compile the kernel:
   ```bash
   make oldconfig
   make -j $(nproc)
   ```

4. Replace the WSL2 Kernel  
   a. Shutdown WSL2:
   ```bash
   wsl --shutdown
   ```
   b. Copy the compiled kernel image to the Windows kernel location. Adjust the paths as needed:
   ```powershell
   # Run in PowerShell as Administrator
   Copy-Item -Path "<path-to-WSL2-Linux-Kernel>/arch/x86/boot/bzImage" -Destination "C:\Windows\System32\lxss\tools\kernel"
   ```
   c. Restart WSL2 to load the new kernel.

