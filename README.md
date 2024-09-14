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

### Grafana installieren



## Tools

### k8sgpt - KI Analyse Tool
