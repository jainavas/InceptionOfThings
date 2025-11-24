#!/bin/bash
set -e

echo "Instalando K3s Agent..."

apt-get update
apt-get upgrade -y
apt-get install -y curl wget net-tools vim git

# Esperar a que el server esté listo
echo "Esperando al control plane..."
for i in {1..120}; do
  if ping -c 1 192.168.56.110 &> /dev/null; then
    break
  fi
  sleep 2
done

# Esperar a que el server escriba el token
echo "Esperando token..."
for i in {1..60}; do
  if [ -f /vagrant/token ]; then
    TOKEN=$(cat /vagrant/token)
    echo "Token obtenido"
    break
  fi
  sleep 2
done

# Instalar K3s en modo agent
curl -sfL https://get.k3s.io | K3S_URL="https://192.168.56.110:6443" K3S_TOKEN="$TOKEN" sh -

echo "Agent listo"