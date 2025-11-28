# Inception of Things (IoT)

Proyecto de administración de sistemas en 42 Madrid que introduce los fundamentos de Kubernetes mediante K3s, Vagrant y GitOps con Argo CD.

## 📋 Descripción

El proyecto se divide en tres partes progresivas que enseñan infraestructura moderna:

### Part 1: K3s + Vagrant
Configuración de un cluster Kubernetes con dos nodos usando Vagrant:
- **Server**: Control plane de K3s
- **Worker**: Nodo agente

**Conceptos**: Orquestación básica, comunicación inter-nodos, token sharing HTTP.

### Part 2: K3s + Aplicaciones
Despliegue de tres aplicaciones web en K3s con Ingress routing basado en hosts:
- `app1.com` → App 1 (1 réplica)
- `app2.com` → App 2 (3 réplicas)
- `app3.com` → App 3 (default)

**Conceptos**: Deployments, Services, Ingress, escalado horizontal.

### Part 3: K3d + Argo CD
GitOps workflow con K3d (K3s en Docker) y Argo CD para continuous deployment:
- Cluster K3d local
- Argo CD monitorea GitHub repository
- Auto-sync en cambios de versión

**Conceptos**: GitOps, CI/CD, sincronización automática, self-healing.

## 🛠️ Requisitos

- Vagrant + libvirt provider (Part 1-2)
- Docker (Part 3)
- kubectl
- k3d (Part 3)
- Git + GitHub account (Part 3)

## 📁 Estructura del Proyecto

```
.
├── p1/                    # Part 1: K3s + Vagrant (2 nodos)
│   ├── Vagrantfile
│   ├── scripts/
│   │   ├── server-setup.sh
│   │   └── agent-setup.sh
│   └── confs/
├── p2/                    # Part 2: K3s + 3 Apps + Ingress
│   ├── Vagrantfile
│   ├── scripts/
│   │   ├── setup.sh
│   │   └── deploy.sh
│   └── confs/
│       ├── app1.yaml
│       ├── app2.yaml
│       ├── app3.yaml
│       └── ingress.yaml
├── p3/                    # Part 3: K3d + Argo CD
│   ├── scripts/
│   │   ├── setup.sh
│   │   ├── deploy-app.sh
│   │   └── cleanup.sh
│   ├── confs/
│   │   └── deployment.yaml
│   ├── README.md
│   └── CHECKLIST.md
└── bonus/                 # Bonus: GitLab local + Kubernetes
```

## 🚀 Cómo empezar

### Part 1
```bash
cd p1
vagrant up
vagrant ssh jainavasS
kubectl get nodes
```

### Part 2
```bash
cd p2
vagrant up
# Acceder a través de 192.168.56.110 con hosts: app1.com, app2.com, app3.com
```

### Part 3
```bash
cd p3
./scripts/setup.sh
./scripts/deploy-app.sh
kubectl port-forward svc/argocd-server -n argocd 8081:443
# UI en https://localhost:8081
```

## 🎯 Conceptos Clave

### Kubernetes Basics
- **Pods**: Unidad mínima de despliegue
- **Deployments**: Replicación y actualización declarativa
- **Services**: Exposición de aplicaciones
- **Ingress**: Routing HTTP/HTTPS basado en reglas

### K3s
Kubernetes ligero (single binary, perfecto para desarrollo y edge computing).

### K3d
K3s dentro de Docker. Útil para desarrollo local sin sobrecargar la máquina.

### GitOps
Git como fuente de verdad. Argo CD sincroniza automáticamente el estado deseado (en Git) con el estado actual del cluster.

### Token Sharing
En Part 1, el server expone el token K3s vía HTTP para que el worker pueda unirse al cluster sin necesidad de shared folders o NFS.

## 📊 Lo Aprendido

✅ **Orquestación de contenedores** desde cero  
✅ **Infraestructura como código** (Vagrant + YAML)  
✅ **Networking y comunicación inter-nodos**  
✅ **Escalado horizontal** de aplicaciones  
✅ **GitOps workflow** con Argo CD  
✅ **Resolución de problemas** en ambientes con permisos limitados  

## 🔧 Troubleshooting

### Part 1: Worker no se conecta al server
```bash
# Verificar que el token HTTP está disponible
curl http://192.168.56.110:8080/token

# Ver logs del server
vagrant ssh jainavasS
sudo journalctl -u k3s -n 50
```

### Part 3: Argo CD no sincroniza
```bash
kubectl describe application wil-playground -n argocd
kubectl logs -n argocd deployment/argocd-application-controller
```

## 📚 Recursos

- [K3s Documentation](https://docs.k3s.io/)
- [Kubernetes Official Docs](https://kubernetes.io/docs/)
- [Argo CD Documentation](https://argo-cd.readthedocs.io/)
- [Vagrant Documentation](https://www.vagrantup.com/docs)

## 📝 Notas

- El proyecto debe completarse dentro de una máquina virtual en el cluster de 42
- No hay acceso sudo directo, lo que requiere soluciones creativas (como el token HTTP)
- La defensa requiere entender el "por qué" detrás de cada decisión técnica

## 🏆 Resultado

Al completar este proyecto, tendrás una comprensión sólida de cómo funcionan las infraestructuras modernas basadas en Kubernetes y estarás preparado para roles de DevOps/SRE.

---

**Autor**: jainavas (42 Madrid)  
**Fecha**: 2025  
**Status**: ✅ Completado
