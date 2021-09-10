# Private Cloud

Private Kubernetes Cloud based on Rasperry Pi 4

## Basic configuration for Raspberry Pi 4

1. install [Ubuntu Server 20.04.3 LTS (64bit)](https://ubuntu.com/download/raspberry-pi) using [Raspberry Pi Imager](https://www.raspberrypi.org/software/) on microSD card.
2. an static WLAN address is achieved by the ``network-config`` file in the drive root of the microSD card.
3. the SSH server is accessed through the ``ssh`` file in the drive root of the MicroSD card.
4. Insert the micro SD card into the Raspberry Pi and connect the power.
5. wait until Raspberry Pi has booted. Can be easily determined by ``ping raspberrypi-ip-address``.
6. Open an SSH connection with ``ssh ubuntu@raspberry-ip-address``. The initial password is ``ubuntu``. Change the password and reconnect with SSH.
7. Update the operating system with ``sudo apt update && sudo apt upgrade -y``.
8. Timezone ``sudo timedatectl set-timezone Europe/Berlin``.
9. Adjust ``/etc/hosts``.
10. Set unique hostname: ``sudo hostnamectl set-hostname <hostname>``

## Installation K3S

### Vorbereitung Installation K3S

Auf jeden Raspberry Pi, auf dem K3S installiert werden soll sind folgende Änderungen vorzunehmen:

```sh
# IPTABLES aktivieren
sudo iptables -F && sudo update-alternatives --set iptables /usr/sbin/iptables-legacy && sudo update-alternatives --set ip6tables /usr/sbin/ip6tables-legacy
# CGROUP aktivieren
# dabei die eine exestierende Zeile um folgenden Eintrag am Zeilenende ergänzen
#         cgroup_memory=1 cgroup_enable=memory
sudo nano /boot/cmdline.txt

sudo reboot
```

### Installation ersten Master

- Installation: ``curl -sfL https://get.k3s.io | sh -``
- Test Version: ``sudo kubectl version``
- Test Info: ``sudo kubectl cluster-info``
- Test Knoten: ``sudo kubectl get node``
- Uninstall: ``/usr/local/bin/k3s-uninstall.sh``
- Cluster-Konfiguration: ``sudo cat /etc/rancher/k3s/k3s.yaml``

### Installation Worker

- Token zeigen: ``sudo cat /var/lib/rancher/k3s/server/node-token``
- Installation: ``curl -sfL https://get.k3s.io | K3S_URL=https://192.168.0.101:6443 K3S_TOKEN=K10204ddc089cfe0f49f9b69ae5e410fcb626a69cacedd3f0ec9ae0d51af1c80125::server:fd8c7f492b9e72e5c64453c9673938e6 sh -``
- Uninstall: ``/usr/local/bin/k3s-agent-uninstall.sh``

## Installation Dashboard

```sh
GITHUB_URL=https://github.com/kubernetes/dashboard/releases
VERSION_KUBE_DASHBOARD=$(curl -w '%{url_effective}' -I -L -s -S ${GITHUB_URL}/latest -o /dev/null | sed -e 's|.*/||')
sudo k3s kubectl create -f https://raw.githubusercontent.com/kubernetes/dashboard/${VERSION_KUBE_DASHBOARD}/aio/deploy/recommended.yaml

# Rollen und Benutzer anlegen
kubectl create -f dashboard.admin-user.yml -f dashboard.admin-user-role.yml
# Token holen
kubectl -n kubernetes-dashboard describe secret admin-user-token | grep '^token'
# Dahsboard exposen
kubectl proxy
```

## Installieren [Prometheus](https://sysdig.com/blog/kubernetes-monitoring-prometheus/)

```sh
# Installation
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo add stable https://kubernetes-charts.storage.googleapis.com/
helm repo update
# Prometheus-Server exposen (http://r1.local:9090/targets)
export POD_NAME=$(sudo kubectl get pods --namespace prometheus -l "app=prometheus,component=server" -o jsonpath="{.items[0].metadata.name}")
sudo kubectl --namespace prometheus port-forward $POD_NAME 9090 --address=0.0.0.0
# Prometheus-Alertmanager exposen (http://r1.local:9093)
export POD_NAME=$(sudo kubectl get pods --namespace prometheus -l "app=prometheus,component=alertmanager" -o jsonpath="{.items[0].metadata.name}")
sudo kubectl --namespace prometheus port-forward $POD_NAME 9093 --address=0.0.0.0

# The Prometheus PushGateway can be accessed via port 9091 on the following DNS name from within your cluster:
#       prometheus-pushgateway.prometheus.svc.cluster.local
# Prometheus-PushGateway exposen: (http://r1.local:9091)
export POD_NAME=$(sudo kubectl get pods --namespace prometheus -l "app=prometheus,component=pushgateway" -o jsonpath="{.items[0].metadata.name}")
sudo kubectl --namespace prometheus port-forward $POD_NAME 9091 --address=0.0.0.0
```

## Installieren Grafana auf lokalen Docker

- ``docker run -d -p 3000:3000 --name grafana grafana/grafan``

## Installieren Docker für ARM-Builds

- Installation: ``curl -fsSL https://get.docker.com | sh``

<!-- 
## Installation MicroK8s

Follow [this](https://ubuntu.com/tutorials/how-to-kubernetes-cluster-on-raspberry-pi#4-installing-microk8s) guide.

``microk8s join 192.168.0.101:25000/d1c352ae6828699ececb08cdca9720e9/de7fca24feb5`` -->
