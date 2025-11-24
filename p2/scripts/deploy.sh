#!/bin/bash
set -e

echo "Esperando a K3s..."
sleep 30

echo "Desplegando aplicaciones..."

# Aplicar todos los manifiestos
kubectl apply -f /vagrant/confs/app1-deployment.yaml
kubectl apply -f /vagrant/confs/app1-service.yaml
kubectl apply -f /vagrant/confs/app2-deployment.yaml
kubectl apply -f /vagrant/confs/app2-service.yaml
kubectl apply -f /vagrant/confs/app3-deployment.yaml
kubectl apply -f /vagrant/confs/app3-service.yaml
kubectl apply -f /vagrant/confs/ingress.yaml

echo "Esperando a que los pods arranquen..."
sleep 15

echo "Estado de los pods:"
kubectl get pods

echo "Estado de los servicios:"
kubectl get svc

echo "Estado del Ingress:"
kubectl get ingress

echo "Aplicaciones desplegadas"
