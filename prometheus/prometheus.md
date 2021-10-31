
```sh
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
```
