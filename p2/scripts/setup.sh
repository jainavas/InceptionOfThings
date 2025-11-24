#!/bin/bash
set -e

echo "Instalando K3s en modo server..."

apt-get update
apt-get upgrade -y
apt-get install -y curl wget net-tools vim git

# Instalar K3s
curl -sfL https://get.k3s.io | K3S_KUBECONFIG_MODE="644" sh -

sleep 15

echo "K3s instalado"
