#!/bin/bash

echo "=== Limpiando Part 3 ==="

CLUSTER_NAME="iot-cluster"

# Eliminar cluster
echo "Eliminando cluster K3d: $CLUSTER_NAME"
k3d cluster delete $CLUSTER_NAME

echo "✓ Cluster eliminado"
echo ""
echo "Para volver a crear, ejecuta: ./scripts/setup.sh"
