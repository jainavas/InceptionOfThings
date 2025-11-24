#!/bin/bash
set -e

echo "Instalando K3s Control Plane..."

apt-get update
apt-get upgrade -y
apt-get install -y curl wget net-tools vim git

# Instalar K3s
curl -sfL https://get.k3s.io | K3S_KUBECONFIG_MODE="644" sh -

# Esperar a que K3s genere el token
echo "Esperando token..."
for i in {1..30}; do
  if [ -f /var/lib/rancher/k3s/server/node-token ]; then
    break
  fi
  sleep 2
done

# Crear /vagrant si no existe
mkdir -p /vagrant

# Copiar a /vagrant para que el worker lo acceda
cp /var/lib/rancher/k3s/server/node-token /vagrant/token
chmod 644 /vagrant/token

echo "Control Plane listo"