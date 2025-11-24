#!/bin/bash
set -e

echo "=== Instalando K3s Agent ==="

# Instalar dependencias
apt-get update -qq
apt-get install -y curl wget net-tools

# Esperar a que el server esté accesible
echo "Esperando a que el server esté disponible..."
for i in {1..120}; do
  if ping -c 1 -W 1 192.168.56.110 &> /dev/null; then
    echo "Server alcanzable"
    break
  fi
  sleep 2
done

# Esperar al token via HTTP del server
echo "Obteniendo token desde el server..."
TOKEN=""
for i in {1..120}; do
  TOKEN=$(curl -s http://192.168.56.110:8080/token 2>/dev/null || echo "")
  if [ -n "$TOKEN" ] && [ "$TOKEN" != "404" ]; then
    echo "Token obtenido correctamente"
    break
  fi
  sleep 2
done

if [ -z "$TOKEN" ]; then
  echo "ERROR: No se pudo obtener el token del server"
  echo "Intentando verificar conectividad:"
  curl -v http://192.168.56.110:8080/token || true
  exit 1
fi

# Instalar K3s en modo agent
echo "Instalando K3s agent..."
curl -sfL https://get.k3s.io | K3S_URL="https://192.168.56.110:6443" \
  K3S_TOKEN="$TOKEN" \
  sh -s - agent \
  --node-ip=192.168.56.111

# Esperar a que el agent esté activo
echo "Esperando a que K3s agent esté ready..."
for i in {1..60}; do
  if systemctl is-active --quiet k3s-agent; then
    echo "K3s agent activo"
    break
  fi
  sleep 2
done

echo "=== Agent K3s listo ==="