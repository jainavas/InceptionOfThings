#!/bin/bash
set -e

echo "=== Instalando K3s Control Plane ==="

# Instalar dependencias
apt-get update -qq
apt-get install -y curl wget net-tools

# Instalar K3s en modo server
echo "Instalando K3s server..."
curl -sfL https://get.k3s.io | K3S_KUBECONFIG_MODE="644" sh -s - server \
  --write-kubeconfig-mode=644 \
  --node-ip=192.168.56.110 \
  --bind-address=192.168.56.110 \
  --advertise-address=192.168.56.110

# Esperar a que K3s esté listo
echo "Esperando a que K3s esté ready..."
for i in {1..60}; do
  if systemctl is-active --quiet k3s; then
    echo "K3s server activo"
    break
  fi
  sleep 2
done

# Esperar a que se genere el token
echo "Esperando token..."
for i in {1..60}; do
  if [ -f /var/lib/rancher/k3s/server/node-token ]; then
    echo "Token encontrado"
    break
  fi
  sleep 2
done

# Exponer el token via HTTP simple para que el worker lo pueda obtener
if [ -f /var/lib/rancher/k3s/server/node-token ]; then
  TOKEN=$(cat /var/lib/rancher/k3s/server/node-token)
  
  # Crear un servidor HTTP simple para servir el token
  mkdir -p /tmp/token-server
  echo "$TOKEN" > /tmp/token-server/token
  
  # Iniciar servidor HTTP en background (se cierra solo después de 1 acceso)
  cd /tmp/token-server
  nohup python3 -m http.server 8080 > /tmp/token-server.log 2>&1 &
  
  echo "Token disponible en http://192.168.56.110:8080/token"
else
  echo "ERROR: Token no encontrado"
  exit 1
fi

# Verificar estado
kubectl get nodes

echo "=== Server K3s listo ==="