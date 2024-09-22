# Installation lokaler K3D Cluster

## Requirements

- Ein funktionierendes Docker-Setup auf dem Host-System.
- Installiertes `k3d`.
- Kubernetes CLI `kubectl` installiert und konfiguriert.
- Helm CLI installiert (für die Verwaltung von Kubernetes-Paketen).

## K3D Cluster

Erstellen Sie einen neuen k3d-Cluster ohne Traefik und öffnen Sie die Ports 80 und 443:

```bash
k3d cluster create kong --servers 1 --agents 3 --port '80:80@loadbalancer' --port '443:443@loadbalancer' --k3s-arg '--disable=traefik@server:0'
```

## Kong Ingress Controller

### Helm-Repository für Kong hinzufügen

Fügen Sie das offizielle Helm-Repository für Kong hinzu und aktualisieren Sie es:

```bash
helm repo add kong https://charts.konghq.com
helm repo update
```

### Kong Ingress Controller installieren

Installieren Sie Kong in einem neuen Namespace `kong`:

```bash
helm install kong kong/kong --namespace kong --create-namespace --set admin.enabled=true --set admin.http.enabled=true
curl http://localhost # test http, answer no route
curl -k https://localhost # test https, answer no route
```

## Kong Ingress Controller testen

Erstellen Sie eine Beispiel-Anwendung im Namespace `default`:

```bash
kubectl apply -f samples/httpbin.yaml
```

Testen Sie die Anwendung:

```bash
curl http://localhost/httpbin/get
```

Wenn die Ausgabe Informationen über den HTTP-GET-Anruf zurückgibt, funktioniert die Ingress-Konfiguration korrekt.

## Grafana Loki

### Helm Repo für Grafana hinzufügen

```bash
helm repo add grafana https://grafana.github.io/helm-charts
helm repo update
```

### Grafana Loki installieren

```bash
# Values extrahieren um Parameter anzupassen
helm show values grafana/loki-stack > loki-grafana/loki.yaml
# Install loki-stack
helm upgrade --install --values loki-grafana/loki.yaml loki grafana/loki-stack -n grafana-loki --create-namespace
# Aufruf über Port Forward
kubectl get pod -n grafana-loki
kubectl port-forward pod/loki-grafana-6d64c8f4f9-lw87h -n grafana-loki 9090:3000 # richtigen pod einsetzen
# Aufruf über Kong Ingress Controller
kubectl apply -f loki-grafana/ingress.yaml
# Initial-Passwort für Admin abrufen
kubectl get secret --namespace grafana-loki loki-grafana -o jsonpath="{.data.admin-password}" | base64 --decode ; echo
````

## [ArgoCD](https://argo-cd.readthedocs.io/en/stable/operator-manual/installation/) installieren

```bash
# lade Helm-Chart
helm repo add argo https://argoproj.github.io/argo-helm
helm repo update
# installiere ArgoCD
helm upgrade --install argocd argo/argo-cd -n argocd --create-namespace -f argo-cd/argo-cd.yaml
```

die Helm-Chart-Datei `argo-cd.yaml` enthält die Konfiguration für die Installation von ArgoCD und wurde wi folgt angepasst:


```yaml
## Server properties
# -- Run server without TLS
## NOTE: This value should be set when you generate params by other means as it changes ports used by ingress template.
server.insecure: true
# -- Value for base href in index.html. Used if Argo CD is running behind reverse proxy under subpath different from /
server.basehref: /argocd/
# -- Used if Argo CD is running behind reverse proxy under subpath different from /
server.rootpath: ''
```

und die Ingress-Definition wurde wie folgt angepasst:

```yaml 
# Argo CD server ingress configuration
ingress:
# -- Enable an ingress resource for the Argo CD server
enabled: true
# -- Specific implementation for ingress controller. One of `generic`, `aws` or `gke`
## Additional configuration might be required in related configuration sections
controller: generic
# -- Additional ingress labels
labels: {}
# -- Additional ingress annotations
## Ref: https://argo-cd.readthedocs.io/en/stable/operator-manual/ingress/#option-1-ssl-passthrough
# annotations: {}
#   # nginx.ingress.kubernetes.io/force-ssl-redirect: "true"
#   # nginx.ingress.kubernetes.io/ssl-passthrough: "true"
annotations:
    konghq.com/strip-path: "true"

# -- Defines which ingress controller will implement the resource
ingressClassName: "kong"

# -- Argo CD server hostname
# @default -- `""` (defaults to global.domain)
hostname: "localhost"

# -- The path to Argo CD server
path: /argocd

# -- Ingress path type. One of `Exact`, `Prefix` or `ImplementationSpecific`
pathType: Prefix

# -- Enable TLS configuration for the hostname defined at `server.ingress.hostname`
## TLS certificate will be retrieved from a TLS secret `argocd-server-tls`
## You can create this secret via `certificate` or `certificateSecret` option
tls: false
```

## Tools

### k8sgpt - KI Analyse Tool
