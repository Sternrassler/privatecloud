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
- Access with ``kubectl`` without admin rights: ``sudo chmod 644 /etc/rancher/k3s/k3s.yaml``

### Installation Worker

- Show token: ``sudo cat /var/lib/rancher/k3s/server/node-token``
- Installation: ``curl -sfL https://get.k3s.io | K3S_URL=https://192.168.0.101:6443 K3S_TOKEN=K10204ddc089cfe0f49f9b69ae5e410fcb626a69cacedd3f0ec9ae0d51af1c80125::server:fd8c7f492b9e72e5c64453c9673938e6 sh -``
- Uninstall: ``/usr/local/bin/k3s-agent-uninstall.sh``

## Installation Dashboard

```sh
GITHUB_URL=https://github.com/kubernetes/dashboard/releases
VERSION_KUBE_DASHBOARD=$(curl -w '%{url_effective}' -I -L -s -S ${GITHUB_URL}/latest -o /dev/null | sed -e 's|.*/||')
sudo k3s kubectl create -f https://raw.githubusercontent.com/kubernetes/dashboard/${VERSION_KUBE_DASHBOARD}/aio/deploy/recommended.yaml

# Create roles and users
kubectl create -f dashboard.admin-user.yml -f dashboard.admin-user-role.yml
# Get tokens
kubectl -n kubernetes-dashboard describe secret admin-user-token | grep '^token'
# Expose Dahsboard
kubectl proxy
# Browser Link
http://localhost:8001/api/v1/namespaces/kubernetes-dashboard/services/https:kubernetes-dashboard:/proxy/#/workloads?namespace=_all
```

## Install Tools for ARM Docker Builds

- Installation Docker: ``curl -fsSL https://get.docker.com | sh``
- Installation NodeJs 14.x: ``curl -sL https://deb.nodesource.com/setup_14.x | sudo -E bash -``

<!-- 
## Installation MicroK8s

Follow [this](https://ubuntu.com/tutorials/how-to-kubernetes-cluster-on-raspberry-pi#4-installing-microk8s) guide.

``microk8s join 192.168.0.101:25000/d1c352ae6828699ececb08cdca9720e9/de7fca24feb5`` -->

## Boinc

```sh
sudo apt install boinc -y
# added 192.168.0.4 to /var/lib/boinc-client/remote_hosts.cfg
sudo nano /var/lib/boinc-client/remote_hosts.cfg
# restart boinc
sudo /etc/init.d/boinc-client restart
```

## Measurement temperature, CPU frequency etc.

- Lade Library: ``sudo apt install libraspberrypi-bin -y``

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