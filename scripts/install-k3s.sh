#!/bin/bash

# Script to install k3s with custom options

curl -sfL https://get.k3s.io | INSTALL_K3S_EXEC="server --disable traefik --disable servicelb --tls-san 192.168.80.2" sh -
