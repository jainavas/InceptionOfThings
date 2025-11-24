# Part 3: K3d y Argo CD

Este part implementa continuous deployment usando K3d (K3s en Docker) y Argo CD.

## Diferencias con Part 1 y 2

- **NO usa Vagrant** (usa Docker directamente)
- **K3d** en lugar de K3s (K3s dentro de contenedores Docker)
- **Argo CD** para continuous deployment desde GitHub

## Requisitos previos

1. **Docker** instalado y corriendo
2. **Git** instalado
3. **Cuenta de GitHub** (para crear el repositorio público)

El script instalará automáticamente:
- kubectl
- k3d

## Setup paso a paso

### 1. Preparar repositorio de GitHub

Crea un repositorio público en GitHub con tus manifiestos de Kubernetes:

```bash
# En tu máquina local
mkdir iot-manifests
cd iot-manifests

# Copiar el deployment de ejemplo
cp /path/to/p3/confs/deployment.yaml .

# Inicializar git
git init
git add deployment.yaml
git commit -m "Initial commit with v1"

# Crear repo en GitHub y pushear
git remote add origin https://github.com/TU_USERNAME/iot-manifests.git
git branch -M main
git push -u origin main
```

**IMPORTANTE:** El nombre del repositorio debe contener el login de alguien del grupo.

### 2. Configurar scripts

Edita `scripts/deploy-app.sh` y cambia:

```bash
GITHUB_REPO="https://github.com/TU_USERNAME/iot-manifests.git"
```

### 3. Ejecutar setup

```bash
cd p3
./scripts/setup.sh
```

Esto:
- Crea un cluster K3d
- Instala Argo CD en namespace `argocd`
- Crea namespace `dev`
- Te da las credenciales de Argo CD

### 4. Configurar la aplicación

```bash
./scripts/deploy-app.sh
```

Esto crea la Application de Argo CD que:
- Monitorea tu repo de GitHub
- Sincroniza automáticamente los cambios
- Despliega en el namespace `dev`

### 5. Acceder a Argo CD UI

En una terminal:
```bash
kubectl port-forward svc/argocd-server -n argocd 8081:443
```

Abre en el navegador: https://localhost:8081

**Credenciales:**
- Usuario: `admin`
- Password: (el que te mostró el script de setup)

### 6. Verificar el despliegue

```bash
# Ver la aplicación en Argo CD
kubectl get application -n argocd

# Ver pods en dev
kubectl get pods -n dev

# Ver servicio
kubectl get svc -n dev

# Probar la aplicación
kubectl port-forward svc/wil-playground-service -n dev 8888:8888
curl http://localhost:8888
# Debería responder: {"status":"ok", "message": "v1"}
```

## Cambiar de versión (v1 → v2)

Este es el punto clave de Part 3: **continuous deployment**.

1. **Editar deployment.yaml en tu repo de GitHub:**

```bash
# En tu repo local iot-manifests
vim deployment.yaml

# Cambiar la línea:
# image: wil42/playground:v1
# Por:
# image: wil42/playground:v2

git add deployment.yaml
git commit -m "Update to v2"
git push
```

2. **Argo CD detecta el cambio automáticamente** (tarda ~3 minutos)

3. **Verificar la actualización:**

```bash
# Ver que el pod se está actualizando
kubectl get pods -n dev -w

# Una vez ready, probar:
curl http://localhost:8888
# Ahora debería responder: {"status":"ok", "message": "v2"}
```

4. **En Argo CD UI** verás:
   - Status: Synced
   - Health: Healthy
   - La imagen actualizada a v2

## Arquitectura

```
Host Machine
│
├─ Docker
│  └─ K3d Cluster (contenedor)
│     │
│     ├─ Namespace: argocd
│     │  └─ Argo CD
│     │     └─ Monitorea GitHub repo
│     │
│     └─ Namespace: dev
│        └─ wil-playground (app)
│           └─ Auto-deploy desde GitHub
│
└─ GitHub
   └─ iot-manifests repo
      └─ deployment.yaml (v1 o v2)
```

## Comandos útiles

### Ver estado del cluster
```bash
kubectl get nodes
kubectl get pods -A
```

### Ver Argo CD
```bash
kubectl get all -n argocd
kubectl get application -n argocd
```

### Ver la aplicación
```bash
kubectl get all -n dev
kubectl logs -n dev deployment/wil-playground
```

### Forzar sincronización en Argo CD
```bash
# Si no quieres esperar los 3 minutos
kubectl patch application wil-playground -n argocd \
  --type merge -p '{"operation":{"sync":{}}}'
```

### Acceder a Argo CD CLI (opcional)
```bash
# Instalar argocd CLI
curl -sSL -o argocd-linux-amd64 https://github.com/argoproj/argo-cd/releases/latest/download/argocd-linux-amd64
sudo install -m 555 argocd-linux-amd64 /usr/local/bin/argocd

# Login
argocd login localhost:8081 --username admin --password <password>

# Ver apps
argocd app list
argocd app get wil-playground
```

## Limpiar

```bash
./scripts/cleanup.sh
```

Esto elimina completamente el cluster K3d.

## Troubleshooting

### Argo CD no sincroniza

**Verificar:**
```bash
kubectl describe application wil-playground -n argocd
```

**Forzar sync:**
```bash
kubectl -n argocd patch application wil-playground \
  --type merge -p '{"spec":{"syncPolicy":{"automated":null}}}'
  
# Luego sync manual
kubectl -n argocd patch application wil-playground \
  --type merge -p '{"operation":{"sync":{}}}'
```

### Pod no arranca

```bash
kubectl describe pod -n dev <pod-name>
kubectl logs -n dev <pod-name>
```

### No puedo acceder a la app

```bash
# Verificar que el servicio existe
kubectl get svc -n dev

# Port forward
kubectl port-forward svc/wil-playground-service -n dev 8888:8888

# Probar
curl http://localhost:8888
```

### K3d cluster no crea

```bash
# Ver logs
docker logs <container-id>

# Recrear
k3d cluster delete iot-cluster
./scripts/setup.sh
```

## Para la defensa

**Demostración completa:**

1. Ejecutar `setup.sh` → Cluster creado
2. Ejecutar `deploy-app.sh` → App desplegada con v1
3. Verificar: `curl http://localhost:8888` → responde "v1"
4. Cambiar en GitHub: `v1` → `v2`
5. Esperar ~3 min (o forzar sync)
6. Verificar: `curl http://localhost:8888` → responde "v2"
7. Mostrar Argo CD UI: estado Synced + Healthy

**Explicar:**
- K3d = K3s en Docker (más ligero que VMs)
- Argo CD = GitOps (Git como source of truth)
- Sync policy automated = Argo CD monitorea GitHub cada 3 min
- selfHeal = Si borras un pod, Argo CD lo recrea
