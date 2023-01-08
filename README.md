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

### Preparation Installation K3S

On each Raspberry Pi on which K3S is to be installed, the following changes must be made:

```sh
# IPTABLES activate
sudo iptables -F && sudo update-alternatives --set iptables /usr/sbin/iptables-legacy && sudo update-alternatives --set ip6tables /usr/sbin/ip6tables-legacy
# CGROUP activate
# add the following entry at the end of the line to the existing line
#         cgroup_memory=1 cgroup_enable=memory
sudo nano /boot/cmdline.txt

sudo reboot
```

### Installation first master

- Installation: ``curl -sfL https://get.k3s.io | sh -``
- Test Version: ``sudo kubectl version``
- Test Info: ``sudo kubectl cluster-info``
- Test Knoten: ``sudo kubectl get node``
- Uninstall: ``/usr/local/bin/k3s-uninstall.sh``
- Cluster-Konfiguration: ``sudo cat /etc/rancher/k3s/k3s.yaml``
- Access with ``kubectl`` without admin rights: ``sudo chmod 644 /etc/rancher/k3s/k3s.yaml``

### Installation Worker

- Show token on master node: ``sudo cat /var/lib/rancher/k3s/server/node-token``
- Installation: ``curl -sfL https://get.k3s.io | K3S_URL=https://192.168.0.101:6443 K3S_TOKEN=K10679d86ff477d75e28bf3e2db42e34d0a6f6d9186b816fe80288f401fbb020804::server:7ded4bc2e1234491ea7c07173ecefff9 sh -``
- Uninstall: ``/usr/local/bin/k3s-agent-uninstall.sh``

## Installation Dashboard

```sh
GITHUB_URL=https://github.com/kubernetes/dashboard/releases
VERSION_KUBE_DASHBOARD=$(curl -w '%{url_effective}' -I -L -s -S ${GITHUB_URL}/latest -o /dev/null | sed -e 's|.*/||')
sudo k3s kubectl create -f https://raw.githubusercontent.com/kubernetes/dashboard/${VERSION_KUBE_DASHBOARD}/aio/deploy/recommended.yaml

# Create roles and users
kubectl create -f dashboard.admin-user.yml -f dashboard.admin-user-role.yml
# Expose Dahsboard
kubectl proxy
# Browser Link
http://localhost:8001/api/v1/namespaces/kubernetes-dashboard/services/https:kubernetes-dashboard:/proxy/#/workloads?namespace=_all
# Get Token
kubectl -n kubernetes-dashboard create token admin-user
```

## Installation Traefik Ingress Controller Dashboard

```sh
# Add dashboard entry to HELM chart
sudo nano /var/lib/rancher/k3s/server/manifests/traefik.yaml
# as follows
spec:
  chart: https://%{KUBERNETES_API}%/static/charts/traefik-1.81.0.tgz
  set:
    rbac.enabled: "true"
    ssl.enabled: "true"
    metrics.prometheus.enabled: "true"
    kubernetes.ingressEndpoint.useDefaultPublishedService: "true"
    image: "rancher/library-traefik"
    dashboard.enabled: "true"        # <-- add this line
    dashboard.domain: "your domain"  # <-- add this line
# HELM automatically detects the change and performs all necessary actions
# create default certificate. The certificate is issued to *.navida.dev and the host r1.navida.dev listens to the IP 192.168.0.101
# You should adjust the certificate and IP according to your environment and requirements.
kubectl create secret tls navida.dev --cert=navida.dev/navida.dev.cer --key=navida.dev/navida.dev.key -n kube-system
kubectl apply -f ingress-traefik/default-certificate.yaml
# Enable the dashboard route
kubectl apply -f ingress-traefik/traefik-dashbord.yml
# The dashboard can now be accessed with http://r1.navida.dev/dashboard/ (the slash at the end must be included)

# Sample Application:
kubectl apply -f ingress-traefik/route-whoami.yaml
# The Sample can now be accessed with http://r1.navida.dev/whoami/ (the slash at the end must be included)
```

## Simple Measurement temperature, CPU frequency etc

- Load Library: ``sudo apt install libraspberrypi-bin -y``
- Create``measure.sh``:

    ```sh
    #!/bin/bash
    Counter=14
    DisplayHeader="Time       Temp     CPU     Core         Health           Vcore"
    while true ; do
      let ++Counter
      if [ ${Counter} -eq 15 ]; then
        echo -e "${DisplayHeader}"
        Counter=0
      fi
      Health=$(perl -e "printf \"%19b\n\", $(vcgencmd get_throttled | cut -f2 -d=)")
      Temp=$(vcgencmd measure_temp | cut -f2 -d=)
      Clockspeed=$(vcgencmd measure_clock arm | awk -F"=" '{printf ("%0.0f",$2/1000000); }' )
      Corespeed=$(vcgencmd measure_clock core | awk -F"=" '{printf ("%0.0f",$2/1000000); }' )
      CoreVolt=$(vcgencmd measure_volts | cut -f2 -d= | sed 's/000//')
      echo -e "$(date '+%H:%M:%S')  ${Temp}  $(printf '%4s' ${Clockspeed})MHz $(printf '%4s' ${Corespeed})MHz  $(printf '%020u' ${Health})  ${CoreVolt}"
      sleep 10
    done
    ```

## Install and configure Prometheus

- Install prometheus with: ``kubectl apply -f prometheus/prometheus-deployment.yaml`` Deployment, the service and the IngressRoute are installed on the CLuster.
- The Prometheus GUI can then be called with ``https://prometheus.navida.dev/``. Of course, the host url should be adapted to your conditions.

## [smarter-device-manager](smarter-device-manager.md)

## [alternative k8s](https://anthonynsimon.com/blog/kubernetes-cluster-raspberry-pi/)
