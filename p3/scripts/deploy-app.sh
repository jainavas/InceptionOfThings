#!/bin/bash
set -e

echo "=== Configurando aplicación en Argo CD ==="

# Variables - CAMBIAR SEGÚN TU REPO
GITHUB_REPO="https://github.com/jainavas/iot-manifests-jainavas.git"
APP_NAME="wil-playground"
NAMESPACE="dev"
PATH_IN_REPO="."  # Si los manifiestos están en la raíz del repo

echo "GitHub repo: $GITHUB_REPO"
echo "App name: $APP_NAME"
echo "Namespace: $NAMESPACE"
echo ""

# Crear Application en Argo CD
cat <<EOF | kubectl apply -f -
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: $APP_NAME
  namespace: argocd
spec:
  project: default
  source:
    repoURL: $GITHUB_REPO
    targetRevision: HEAD
    path: $PATH_IN_REPO
  destination:
    server: https://kubernetes.default.svc
    namespace: $NAMESPACE
  syncPolicy:
    automated:
      prune: true
      selfHeal: true
    syncOptions:
    - CreateNamespace=true
EOF

echo ""
echo "✓ Aplicación configurada en Argo CD"
echo ""
echo "Verificar estado:"
echo "  kubectl get application -n argocd"
echo ""
echo "Ver detalles:"
echo "  kubectl describe application $APP_NAME -n argocd"
echo ""
echo "Ver pods en namespace dev:"
echo "  kubectl get pods -n $NAMESPACE"
echo ""
