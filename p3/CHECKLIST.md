# ✅ Checklist Part 3 - K3d y Argo CD

## Pre-requisitos

- [ ] Docker instalado y corriendo (`docker ps` funciona)
- [ ] Git instalado
- [ ] Cuenta de GitHub (para crear repo público)

## Setup inicial

### 1. Crear repositorio de GitHub

- [ ] Crear repo público en GitHub
- [ ] Nombre del repo **debe contener** el login de alguien del grupo
- [ ] Ejemplo: `iot-manifests-jnavajas` o `jnavajas-iot-manifests`

### 2. Preparar manifiestos

- [ ] Copiar `p3/confs/deployment.yaml` a tu repo local
- [ ] Commit y push a GitHub:

```bash
cd /path/to/tu/repo
cp /path/to/p3/confs/deployment.yaml .
git add deployment.yaml
git commit -m "Initial commit with v1"
git push origin main
```

### 3. Configurar scripts

- [ ] Editar `p3/scripts/deploy-app.sh`
- [ ] Cambiar `GITHUB_REPO` a tu URL de GitHub
- [ ] Guardar el archivo

## Ejecución

### 4. Setup del cluster

```bash
cd p3
./scripts/setup.sh
```

**Verificar:**
- [ ] Script termina sin errores
- [ ] Te muestra usuario y password de Argo CD
- [ ] Cluster K3d creado: `k3d cluster list`

### 5. Verificar cluster

```bash
kubectl get nodes
```

**Debe mostrar:**
- [ ] Al menos 1 nodo en estado "Ready"

```bash
kubectl get pods -n argocd
```

**Debe mostrar:**
- [ ] Todos los pods de Argo CD en "Running"

### 6. Desplegar aplicación

```bash
./scripts/deploy-app.sh
```

**Verificar:**
- [ ] Application creada: `kubectl get application -n argocd`
- [ ] Pod en namespace dev: `kubectl get pods -n dev`

### 7. Acceder a Argo CD UI

**Terminal 1:**
```bash
kubectl port-forward svc/argocd-server -n argocd 8081:443
```

**Navegador:**
- [ ] Abrir https://localhost:8081
- [ ] Aceptar certificado self-signed
- [ ] Login con admin / <password del setup>
- [ ] Ver aplicación "wil-playground"
- [ ] Status debe ser "Synced" y "Healthy"

### 8. Verificar aplicación v1

```bash
# Terminal 2
kubectl port-forward svc/wil-playground-service -n dev 8888:8888
```

```bash
# Terminal 3
curl http://localhost:8888
```

**Debe responder:**
- [ ] `{"status":"ok", "message": "v1"}`

## Demostración de continuous deployment

### 9. Cambiar a v2

**En tu repo local:**

```bash
cd /path/to/tu/repo
vim deployment.yaml
```

- [ ] Cambiar línea: `image: wil42/playground:v1`
- [ ] Por: `image: wil42/playground:v2`

```bash
git add deployment.yaml
git commit -m "Update to v2"
git push origin main
```

### 10. Esperar sincronización

**Argo CD sincroniza cada ~3 minutos automáticamente**

**Método 1 - Esperar:**
- [ ] Esperar 3-5 minutos
- [ ] Observar en Argo CD UI: Application status cambia

**Método 2 - Forzar (opcional):**
```bash
kubectl patch application wil-playground -n argocd \
  --type merge -p '{"operation":{"sync":{}}}'
```

### 11. Verificar actualización

```bash
kubectl get pods -n dev -w
```

- [ ] Ver que el pod anterior termina (Terminating)
- [ ] Ver que nuevo pod arranca (Running)

```bash
curl http://localhost:8888
```

**Ahora debe responder:**
- [ ] `{"status":"ok", "message": "v2"}`

### 12. Verificar en Argo CD UI

En https://localhost:8081:
- [ ] Application status: "Synced"
- [ ] Health: "Healthy"
- [ ] Image en el pod: `wil42/playground:v2`
- [ ] Última sincronización: hace pocos minutos

## Para la defensa

### Demostración completa (orden recomendado)

1. **Mostrar el setup:**
   ```bash
   k3d cluster list
   kubectl get nodes
   kubectl get pods -A
   ```

2. **Mostrar namespaces:**
   ```bash
   kubectl get ns
   # Debe mostrar: argocd y dev
   ```

3. **Mostrar Argo CD UI:**
   - Login y mostrar la aplicación
   - Explicar el sync policy (automated)

4. **Mostrar aplicación funcionando (v1):**
   ```bash
   kubectl get pods -n dev
   curl http://localhost:8888  # Responde v1
   ```

5. **Mostrar repo de GitHub:**
   - Abrir en navegador
   - Mostrar deployment.yaml con v1

6. **Hacer el cambio v1 → v2:**
   - Editar deployment.yaml en GitHub (o push local)
   - Mostrar commit en GitHub

7. **Esperar/forzar sincronización:**
   - Mostrar en Argo CD UI cómo detecta el cambio
   - Ver que inicia la sincronización

8. **Verificar actualización:**
   ```bash
   kubectl get pods -n dev  # Nuevo pod
   curl http://localhost:8888  # Ahora responde v2
   ```

9. **Explicar:**
   - GitOps = Git como source of truth
   - Argo CD monitorea GitHub cada 3 min
   - Auto-sync + self-heal
   - Rollback = git revert + push

### Preguntas posibles

**¿Qué es K3d?**
- K3s dentro de Docker
- Más ligero y rápido que VMs
- Ideal para desarrollo local

**¿Diferencia entre K3s y K3d?**
- K3s: instalar en máquina/VM
- K3d: K3s en contenedor Docker

**¿Qué es Argo CD?**
- GitOps tool
- Sincroniza cluster K8s con repo Git
- Automated continuous deployment

**¿Cómo funciona el sync?**
- Argo CD hace poll a GitHub cada 3 min
- Compara estado actual vs deseado (Git)
- Si hay diferencia, aplica cambios

**¿Por qué dos namespaces?**
- `argocd`: para Argo CD mismo
- `dev`: para las aplicaciones
- Separación de concerns

**¿Qué pasa si borro un pod manualmente?**
- Argo CD lo recrea (selfHeal: true)
- Git = truth, cluster se adapta a Git

## Troubleshooting

### Argo CD no sincroniza

```bash
# Ver eventos
kubectl describe application wil-playground -n argocd

# Ver logs de Argo CD
kubectl logs -n argocd deployment/argocd-application-controller

# Forzar sync
kubectl patch application wil-playground -n argocd \
  --type merge -p '{"operation":{"sync":{}}}'
```

### Pod no arranca

```bash
kubectl describe pod -n dev <pod-name>
kubectl logs -n dev <pod-name>

# Ver eventos del namespace
kubectl get events -n dev
```

### No puedo acceder a Argo CD UI

```bash
# Verificar que port-forward está corriendo
ps aux | grep "port-forward"

# Verificar servicio de Argo CD
kubectl get svc -n argocd argocd-server

# Reintentar port-forward
kubectl port-forward svc/argocd-server -n argocd 8081:443
```

### Error de permisos en Docker

```bash
# Añadir usuario a grupo docker (requiere logout/login)
sudo usermod -aG docker $USER

# O usar sudo
sudo ./scripts/setup.sh
```

## Limpieza

```bash
./scripts/cleanup.sh
```

- [ ] Cluster eliminado
- [ ] Contenedores Docker de K3d eliminados

## Resumen de comandos útiles

```bash
# Cluster
k3d cluster list
k3d cluster delete iot-cluster

# Namespaces
kubectl get ns

# Argo CD
kubectl get application -n argocd
kubectl get pods -n argocd

# Aplicación
kubectl get pods -n dev
kubectl logs -n dev <pod-name>

# Port forwarding
kubectl port-forward svc/argocd-server -n argocd 8081:443
kubectl port-forward svc/wil-playground-service -n dev 8888:8888

# Testing
curl http://localhost:8888
```

## Éxito = ✅

Si puedes:
1. Crear el cluster K3d
2. Instalar Argo CD
3. Desplegar la app desde GitHub
4. Cambiar versión en GitHub
5. Ver que Argo CD actualiza automáticamente
6. Verificar que la app cambió de v1 a v2

**¡Part 3 completo! 🎉**
