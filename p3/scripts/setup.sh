#!/bin/bash
set -e

echo "=== Part 3: K3d + Argo CD Setup ==="
echo ""

# Variables
CLUSTER_NAME="iot-cluster"
ARGOCD_NAMESPACE="argocd"
DEV_NAMESPACE="dev"
GITHUB_REPO="https://github.com/jainavas/iot-manifests-jainavas.git"

echo "Verificando dependencias..."

# Verificar Docker
if ! command -v docker &> /dev/null; then
    echo "ERROR: Docker no está instalado"
    echo "Instala Docker primero: https://docs.docker.com/engine/install/"
    exit 1
fi

echo "✓ Docker instalado"

# Verificar/Instalar kubectl
if ! command -v kubectl &> /dev/null; then
    echo "Instalando kubectl..."
    curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
    chmod +x kubectl
    sudo mv kubectl /usr/local/bin/ 2>/dev/null || mv kubectl ~/bin/
fi

echo "✓ kubectl instalado"

# Verificar/Instalar k3d
if ! command -v k3d &> /dev/null; then
    echo "Instalando k3d..."
    curl -s https://raw.githubusercontent.com/k3d-io/k3d/main/install.sh | bash
fi

echo "✓ k3d instalado"
echo ""

# Eliminar cluster si existe
echo "Limpiando cluster anterior (si existe)..."
k3d cluster delete $CLUSTER_NAME 2>/dev/null || true

# Crear cluster K3d
echo "Creando cluster K3d: $CLUSTER_NAME"
k3d cluster create $CLUSTER_NAME \
  --api-port 6443 \
  --port 8080:80@loadbalancer \
  --agents 1

echo "✓ Cluster K3d creado"
echo ""

# Esperar a que el cluster esté listo
echo "Esperando a que el cluster esté listo..."
kubectl wait --for=condition=Ready nodes --all --timeout=120s

# Crear namespace argocd
echo "Creando namespace: $ARGOCD_NAMESPACE"
kubectl create namespace $ARGOCD_NAMESPACE

# Instalar Argo CD
echo "Instalando Argo CD..."
kubectl apply -n $ARGOCD_NAMESPACE -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml

# Esperar a que Argo CD esté ready
echo "Esperando a que Argo CD esté listo (esto puede tardar 2-3 minutos)..."
kubectl wait --for=condition=Ready pods --all -n $ARGOCD_NAMESPACE --timeout=300s

echo "✓ Argo CD instalado"
echo ""

# Crear namespace dev
echo "Creando namespace: $DEV_NAMESPACE"
kubectl create namespace $DEV_NAMESPACE

# Obtener password de Argo CD
echo "Obteniendo password de Argo CD..."
ARGOCD_PASSWORD=$(kubectl -n $ARGOCD_NAMESPACE get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d)

# Port-forward para acceder a Argo CD UI
echo ""
echo "=== Setup completado ==="
echo ""
echo "Información de acceso a Argo CD:"
echo "  Usuario: admin"
echo "  Password: $ARGOCD_PASSWORD"
echo ""
echo "Para acceder a Argo CD UI:"
echo "  kubectl port-forward svc/argocd-server -n argocd 8081:443"
echo "  Luego abre: https://localhost:8081"
echo ""
echo "Para configurar la aplicación, edita y ejecuta: scripts/deploy-app.sh"
echo ""
