# Private Cloud

Private Kubernetes Cloud based on Rasperry Pi 4

## Basic configuration for Raspberry Pi 4

1. install [Raspberry Pi OS Lite](https://www.raspberrypi.org/software/operating-systems/) using [Raspberry Pi Imager](https://www.raspberrypi.org/software/) on microSD card.
2. an automatic WLAN address is achieved by the ``wpa_supplicant.conf`` file in the drive root of the microSD card. To do this, enter the following lines there:

```conf
country=DE
ctrl_interface=DIR=/var/run/wpa_supplicant GROUP=netdev
update_config=1
# WIFI_NAME und WIFI_PASSWORD durch tatsächliche Werte ersetzen
network={
    ssid="WIFI_NAME"
    psk="WIFI_PASSWORD"
}
```

3. the SSH server is accessed through the ``ssh`` file in the drive root of the MicroSD card.
4. Insert the micro SD card into the Raspberry Pi and connect the power.
5. wait until Raspberry Pi has booted. Can be easily determined by ``ping raspberrypi``.
6. Open an SSH connection with ``ssh pi@raspberry``. The initial password is ``raspberry``.
7. Update the operating system with ``sudo apt update && sudo apt upgrade``.
8. (optional) Hostname, timezone, keyboard layout and localisation can be adjusted with ``sudo raspi-config``.
9. the filesystem must be expanded via ``sudo raspi-config`` -> 6 Advanced Option -> A1 Expand Filesystem.
10. Assign a static IP address to the Raspberry PI by adding the following values to ``/etc/dhcpcd.conf``:

```conf
interface wlan0
# Replace the following IP addresses with the desired values
static ip_address=192.168.0.100/24 
static routers=192.168.0.1
static domain_name_servers=8.8.8.8
```

11. Create new user and deactivate default user:

```sh
# sternrassler Replace with your own username
sudo adduser sternrassler
sudo usermod -a -G users,sudo sternrassler
sudo su sternrassler
sudo passwd --lock pi
```

12. Disable SSH for standard user and allow new user (``sudo nano /etc/ssh/sshd_config``):

```conf
# sternrassler Replace with your own username
AllowUsers sternrassler
DenyUsers pi
```

13. Restart Raspberry Pi ``sudo reboot`` and test user login via SSH ``ssh sternrassler@raspberry``.
