# Private Cloud mit K3D

## Voraussetzungen

- [Docker](https://www.docker.com/)
- [k3d](https://k3d.io/)
- [kubectl](https://kubernetes.io/docs/tasks/tools/install-kubectl/)
- [Helm](https://helm.sh/)

## Installation

```bash
# Install k3d
curl -s https://raw.githubusercontent.com/rancher/k3d/main/install.sh | bash
# Install Cluster
k3d cluster create privat --k3s-arg '--disable=traefik@server:0' -p "8080:80@loadbalancer" -p "8443:443@loadbalancer"
# Hole Cluster Konfiguration
k3d kubeconfig merge privat
# Install NGINX Ingress Controller
helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx
helm install nginx-ingress ingress-nginx/ingress-nginx -n ingress-nginx
```
# Test NGINX Ingress Controller
kubectl get pods -n ingress-nginx

```
