# Installation eines Kong-Dashboards in k3d ohne Traefik

## Background

Dieses Dokument beschreibt die Schritte zur Installation eines Kong-Dashboards in einem k3d-Cluster ohne Traefik. Kong ist eine beliebte Open-Source API Gateway- und Microservices-Managementlösung, und k3d ist ein leichtgewichtiges Kubernetes, das in Docker-Containern läuft.

## Requirements

- Ein funktionierendes Docker-Setup auf dem Host-System.
- Installiertes `k3d`.
- Kubernetes CLI `kubectl` installiert und konfiguriert.
- Helm CLI installiert (für die Verwaltung von Kubernetes-Paketen).

## Method

### 1. k3d Cluster erstellen ohne Traefik mit Portfreigabe für 80 und 443

Erstellen Sie einen neuen k3d-Cluster ohne Traefik und öffnen Sie die Ports 80 und 443:

```bash
k3d cluster create kong --servers 1 --agents 2 --port '80:80@loadbalancer' --port '443:443@loadbalancer' --k3s-arg '--disable=traefik@server:0'
```

### 2. PostgreSQL in eigenem Namespace installieren

#### 2.1 Helm-Repository für Bitnami hinzufügen

Fügen Sie das Helm-Repository für Bitnami hinzu und aktualisieren Sie es:

```bash
helm repo add bitnami https://charts.bitnami.com/bitnami
helm repo update
```

#### 2.2 PostgreSQL installieren

Installieren Sie PostgreSQL in einem neuen Namespace `postgres`:

```bash
helm install kong-postgres bitnami/postgresql --namespace postgres --create-namespace
```

#### 2.3 Datenbank-Anmeldeinformationen abrufen

Holen Sie sich die Datenbank-Anmeldeinformationen:

```bash
export POSTGRES_PASSWORD=$(kubectl get secret --namespace postgres kong-postgres-postgresql -o jsonpath="{.data.postgres-password}" | base64 -d)
```

### 3. PostgreSQL-Funktion testen

Erstellen Sie einen temporären Pod mit einem PostgreSQL-Client, um die Funktionalität zu testen:

```bash
kubectl run -i --tty --rm postgres-client --image=bitnami/postgresql --namespace postgres -- bash
```

Verwenden Sie den folgenden Befehl im temporären Pod, um sich mit der PostgreSQL-Datenbank zu verbinden:

```bash
psql -h kong-postgres-postgresql -U postgres -d postgres
```

Verwenden Sie das abgerufene Passwort, wenn Sie dazu aufgefordert werden.

Führen Sie einige einfache SQL-Abfragen aus, um die Datenbankfunktion zu überprüfen:

```sql
SELECT 1;
CREATE TABLE test_table (id SERIAL PRIMARY KEY, name VARCHAR(50));
INSERT INTO test_table (name) VALUES ('Test Name');
SELECT * FROM test_table;
```

### 4. Kong Ingress im eigenen Namespace installieren

#### 4.1 Helm-Repository für Kong hinzufügen

Fügen Sie das offizielle Helm-Repository für Kong hinzu und aktualisieren Sie es:

```bash
helm repo add kong https://charts.konghq.com
helm repo update
```

#### 4.2 Kong installieren

Installieren Sie Kong in einem neuen Namespace `kong`:

```bash
helm install kong kong/kong --namespace kong --create-namespace --set admin.enabled=true --set admin.http.enabled=true
curl http://localhost # test http, answer no route
curl -k https://localhost # test https, answer no route
```

### 5. Kong Ingress testen

Erstellen Sie eine Beispiel-Anwendung im Namespace `default`:

```bash
kubectl apply -f samples/httpbin.yaml
```

Rufen Sie die IP-Adresse ab und testen Sie die Anwendung:

```bash
curl http://localhost/httpbin/get
```

Wenn die Ausgabe Informationen über den HTTP-GET-Anruf zurückgibt, funktioniert die Ingress-Konfiguration korrekt.

### 6. Kong Dashboard (Konga) installieren und mit der obigen Datenbank verbinden

#### 6.1 Konga with Postgres installieren

Erstellen Sie ein Secret it dem Namen 'kong-db-secret':

```bash
kubectl create secret generic kong-db-secret \
  --from-literal=POSTGRES_DB=postgres \
  --from-literal=POSTGRES_USER=postgres \
  --from-literal=POSTGRES_PASSWORD=$POSTGRES_PASSWORD \
  --namespace kong
```
Erstellen Sie ein Deployment und einen Service für Konga:

```bash
kubectl apply -f ingress-kong/kong-dashboard-postgress.yaml
```

### 7. Konga Dashboard testen

#### 7.1 Konga-Dashboard-Zugriff

Finden Sie die IP-Adresse des LoadBalancers für Konga heraus:

```bash
kubectl get svc -n kong
```

#### 7.2 Konga-Dashboard aufrufen

Rufen Sie die IP-Adresse ab und greifen Sie auf das Konga-Dashboard zu:

```bash
http://<LoadBalancer-IP>
```

#### 7.3 Konga konfigurieren

Melden Sie sich beim Konga-Dashboard an und fügen Sie die Verbindung zu Ihrem Kong-Gateway hinzu:

1. Gehen Sie zu `Connections`.
2. Fügen Sie eine neue Verbindung hinzu und geben Sie die URL Ihres Kong-Gateways an (z.B. `http://<Kong-LoadBalancer-IP>:8001`).

## Implementation

Hier sind die Implementierungsschritte zusammengefasst:

1. Erstellen Sie den k3d-Cluster ohne Traefik.
2. Fügen Sie das Bitnami-Helm-Repository hinzu und installieren Sie PostgreSQL im `postgres` Namespace.
3. Testen Sie die PostgreSQL-Datenbank.
4. Fügen Sie das Kong-Helm-Repository hinzu und installieren Sie Kong im `kong` Namespace.
5. Erstellen und testen Sie eine Beispiel-Anwendung und deren Ingress-Ressource.
6. Installieren Sie Konga und verbinden Sie es mit der PostgreSQL-Datenbank.
7. Testen Sie das Konga-Dashboard und die Verbindung zum Kong-Gateway.

## Milestones

1. **Cluster-Erstellung**: k3d-Cluster erfolgreich erstellt.
2. **PostgreSQL-Installation**: PostgreSQL erfolgreich im Cluster installiert.
3. **PostgreSQL-Test**: PostgreSQL-Funktion erfolgreich überprüft.
4. **Kong-Installation**: Kong erfolgreich im Cluster installiert.
5. **Ingress-Test**: Beispiel-Anwendung und Ingress erfolgreich getestet.
6. **Konga-Installation**: Konga erfolgreich installiert und verbunden.

TODO: Change from POSTGRESSQL to mongoDB

```bash
helm install kong-mongo bitnami/mongodb --namespace mongo --create-namespace
export MONGO_PASSWORD=$(kubectl get secret --namespace mongo kong-mongo-mongodb -o jsonpath="{.data.mongodb-password}" | base64 -d)
```
```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: konga
  namespace: kong
spec:
  replicas: 1
  selector:
    matchLabels:
      app: konga
  template:
    metadata:
      labels:
        app: konga
    spec:
      containers:
      - name: konga
        image: pantsel/konga:latest
        ports:
        - containerPort: 1337
        env:
        - name: NODE_ENV
          value: "production"
        - name: DB_ADAPTER
          value: "mongo"
        - name: DB_HOST
          value: "kong-mongo-mongodb.mongo.svc.cluster.local"
        - name: DB_USER
          value: "root"
        - name: DB_PASSWORD
          valueFrom:
            secretKeyRef:
              name: kong-mongo-secret
              key: MONGO_PASSWORD
        - name: DB_DATABASE
          value: "konga"
---
apiVersion: v1
kind: Service
metadata:
  name: konga
  namespace: kong
spec:
  type: LoadBalancer
  ports:
  - port: 80
    targetPort: 1337
    protocol: TCP
  selector:
    app: konga
```
```bash
kubectl create secret generic kong-mongo-secret \
  --from-literal=MONGO_DB=konga \
  --from-literal=MONGO_USER=root \
  --from-literal=MONGO_PASSWORD=$MONGO_PASSWORD \
  --namespace kong
```
```bash
kubectl apply -f ingress-kong/kong-dashboard.yaml
```

