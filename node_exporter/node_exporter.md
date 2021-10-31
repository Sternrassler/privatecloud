# Installation [Node-Exporter](https://github.com/prometheus/node_exporter) for Prometheus

1. choosing the right package:
    - [ARM64](https://github.com/prometheus/node_exporter/releases/download/v1.2.2/node_exporter-1.2.2.linux-arm64.tar.gz) oder 
    - [Raspberry Pi 2 - ARM5](https://github.com/prometheus/node_exporter/releases/download/v1.2.2/node_exporter-1.2.2.linux-armv5.tar.gz)
    - [Raspberry Pi 3 - ARM6](https://github.com/prometheus/node_exporter/releases/download/v1.2.2/node_exporter-1.2.2.linux-armv6.tar.gz)
    - [Raspberry Pi 4 - ARM7](https://github.com/prometheus/node_exporter/releases/download/v1.2.2/node_exporter-1.2.2.linux-armv7.tar.gz)
2. Download the package: ``wget https://github.com/prometheus/node_exporter/releases/download/v1.2.2/node_exporter-1.2.2.linux-arm64.tar.gz``
3. Entpacken de Paketes: ``tar -xvzf node_exporter-1.2.2.linux-arm64.tar.gz``
4. Install node_exporter binary and create required directories:
    - ``sudo cp node_exporter-1.2.2.linux-arm64/node_exporter /usr/local/bin``
    - ``sudo chmod +x /usr/local/bin/node_exporter``
    - ``sudo useradd -m -s /bin/bash node_exporter``
    - ``sudo mkdir /var/lib/node_exporter``
    - ``sudo chown -R node_exporter:node_exporter /var/lib/node_exporter``
5. Setup systemd unit file ``sudo nano /etc/systemd/system/node_exporter.service``:
    ```ini
    [Unit]
    Description=Node Exporter

    [Service]
    ExecStart=/usr/local/bin/node_exporter --collector.textfile.directory /var/lib/node_exporter/textfile_collector

    [Install]
    WantedBy=multi-user.target
    ```
    - ``sudo systemctl daemon-reload``
    - ``sudo systemctl enable node_exporter.service``
    - ``sudo systemctl start node_exporter.service``