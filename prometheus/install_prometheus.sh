#!/bin/bash

# Create user for prometheus (without home directory)
useradd --no-create-home --shell /bin/false prometheus
# Create folder for prometheus library
mkdir /etc/prometheus
mkdir /var/lib/prometheus
# Set folder ownership for prometheus user
chown prometheus:prometheus /etc/prometheus
chown prometheus:prometheus /var/lib/prometheus
# Download and ekstract prometheus
wget https://github.com/prometheus/prometheus/releases/download/v2.30.3/prometheus-2.30.3.linux-arm64.tar.gz
tar xfz prometheus-2.30.3.linux-arm64.tar.gz
# Copy prometheus and promtool to bin directory
cp prometheus-2.30.3.linux-arm64/prometheus /usr/local/bin
cp prometheus-2.30.3.linux-arm64/promtool /usr/local/bin
# Set folder ownership for prometheus user
chown prometheus:prometheus /usr/local/bin/prometheus
chown prometheus:prometheus /usr/local/bin/promtool
# Copy console and console_libraries into prometheus directory
cp -r prometheus-2.30.3.linux-arm64/consoles /etc/prometheus
cp -r prometheus-2.30.3.linux-arm64/console_libraries /etc/prometheus
# Set console and console_libraries ownership for prometheus user
chown -R prometheus:prometheus /etc/prometheus/consoles
chown -R prometheus:prometheus /etc/prometheus/console_libraries
#Create prometheus configuration file with the extension .yml
cat > /etc/prometheus/prometheus.yml <<EOF
global:
  scrape_interval: 15s
scrape_configs:
  - job_name: 'prometheus'
    scrape_interval: 5s
    static_configs:
      - targets: ['localhost:9090']
  - job_name: 'r1'
    scrape_interval: 5s
    static_configs:
      - targets: ['r1:9100']
  - job_name: 'r2'
    scrape_interval: 5s
    static_configs:
      - targets: ['r2:9100']
  - job_name: 'r3'
    scrape_interval: 5s
    static_configs:
      - targets: ['r3:9100']
  - job_name: 'r4'
    scrape_interval: 5s
    static_configs:
      - targets: ['r4:9100']
EOF
# Set ownership of prometheus.yml file for prometheus user
chown prometheus:prometheus /etc/prometheus/prometheus.yml
#Create service for prometheus
cat > /etc/systemd/system/prometheus.service <<EOF
[Unit]
Description=Prometheus
Wants=network-online.target
After=network-online.target
 
[Service]
User=prometheus
Group=prometheus
Type=simple
ExecStart=/usr/local/bin/prometheus \
    --config.file /etc/prometheus/prometheus.yml \
    --storage.tsdb.path /var/lib/prometheus/ \
    --web.console.templates=/etc/prometheus/consoles \
    --web.console.libraries=/etc/prometheus/console_libraries
 
[Install]
WantedBy=multi-user.target
EOF
# Reload, activate and start the daemon to register prometheus.service
systemctl daemon-reload
systemctl enable prometheus
systemctl start prometheus
systemctl status prometheus
