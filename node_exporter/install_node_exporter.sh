#!/bin/bash
wget https://github.com/prometheus/node_exporter/releases/download/v1.2.2/node_exporter-1.2.2.linux-arm64.tar.gz
tar -xvzf node_exporter-1.2.2.linux-arm64.tar.gz
cp node_exporter-1.2.2.linux-arm64/node_exporter /usr/local/bin
chmod +x /usr/local/bin/node_exporter
useradd -m -s /bin/bash node_exporter
mkdir /var/lib/node_exporter
chown -R node_exporter:node_exporter /var/lib/node_exporter

cat > /etc/systemd/system/node_exporter.service <<EOF
[Unit]
Description=Node Exporter

[Service]
ExecStart=/usr/local/bin/node_exporter --collector.textfile.directory /var/lib/node_exporter/textfile_collector

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl enable node_exporter.service
systemctl start node_exporter.service
systemctl status node_exporter.service