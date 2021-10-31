1. Add the APT key used to authenticate packages:
    - ``wget -q -O - https://packages.grafana.com/gpg.key | sudo apt-key add -``
2. Add the Grafana APT repository:
    - ``echo "deb https://packages.grafana.com/oss/deb stable main" | sudo tee -a /etc/apt/sources.list.d/grafana.list``
3. Install Grafana:
    - ``sudo apt-get update``
    - ``sudo apt-get install -y grafana``
4. Enable and start the Grafana server:
    - ``sudo systemctl enable grafana-server``
    - ``sudo systemctl start grafana-server``
