#!/bin/bash

# Load environment variables from .env file
source "$(dirname "$0")/../config.txt"

# Generate grafana configuration file
cat <<EOF > /data/grafana/grafana.ini
[auth.ldap]
enabled = true
config_file = /etc/grafana/ldap.toml
allow_sign_up = true
EOF

# Generate Grafana ldap configurations
cat <<EOF > /data/grafana/ldap.toml
[[servers]]
# Active Directory server host
host = "$DOMAIN_NAME"

# Default port is 389 or 636 if using SSL
port = 389

# Use SSL & Skip SSL verification
use_ssl = false
ssl_skip_verify = true

# Bind DN and password
bind_dn = "CN=$GRAFANA_DOMAIN_USER,OU=Users,OU=ouP-Grafana,OU=ouP-0868,OU=ouProjects,$DOMAIN_NAME_SEP"
bind_password = '$GRAFANA_DOMAIN_PASSWORD'

# Search filter & base DN
search_filter = "(sAMAccountName=%s)"
search_base_dns = ["$DOMAIN_NAME_SEP"]

# Map LDAP attributes to Grafana attributes
[servers.attributes]
name = "givenName"
surname = "sn"
username = "sAMAccountName"
member_of = "memberOf"
email = "mail"

# Group mappings
# Admin group mapping
[[servers.group_mappings]]
group_dn = "CN=sg-0868-GrafanaAdmins,OU=Security Groups,OU=ouP-Grafana,OU=ouP-0868,OU=ouProjects,$DOMAIN_NAME_SEP"
org_role = "Admin"

# Editor group mapping
[[servers.group_mappings]]
group_dn = "CN=sg-0868-GrafanaEditor,OU=Security Groups,OU=ouP-Grafana,OU=ouP-0868,OU=ouProjects,$DOMAIN_NAME_SEP"
org_role = "Editor"

# Viewer group mapping
[[servers.group_mappings]]
group_dn = "CN=sg-0868-GrafanaViewer,OU=Security Groups,OU=ouP-Grafana,OU=ouP-0868,OU=ouProjects,$DOMAIN_NAME_SEP"
org_role = "Viewer"
EOF

# Generate nginx configuration file
cat <<EOF > /data/nginx/conf/nginx.conf
events {
    worker_connections  1024;
}

http {
    # Basic settings for performance and efficiency
    sendfile on;
    tcp_nopush on;
    tcp_nodelay on;
    keepalive_timeout 65;
    types_hash_max_size 2048;

    include /etc/nginx/mime.types;
    default_type application/octet-stream;

    # Logging settings
    access_log /var/log/nginx/access.log;
    error_log /var/log/nginx/error.log;

    # Gzip Settings
    gzip on;
    gzip_disable "msie6";

    # Configuration for Grafana
    server {
        listen 80;
        server_name grafana.$DOMAIN_NAME;

        location / {
            proxy_pass http://$HOST_IP:3000;
            proxy_set_header Host \$host;
            proxy_set_header X-Real-IP \$remote_addr;
            proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
            proxy_set_header X-Forwarded-Proto \$scheme;
        }
    }

    # Configuration for InfluxDB
    server {
        listen 80;
        server_name influxdb.$DOMAIN_NAME;

        location / {
            proxy_pass http://$HOST_IP:8086;
            proxy_set_header Host \$host;
            proxy_set_header X-Real-IP \$remote_addr;
            proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
            proxy_set_header X-Forwarded-Proto \$scheme;
        }
    }
}
EOF

# Generate telegraf configuration file
cat <<EOF > /data/telegraf/telegraf.conf
[[outputs.influxdb_v2]]
  urls = ["$INFLUXDB_URL"]
  token = "$INFLUXDB_TOKEN"
  organization = "$INFLUXDB_ORG_NAME"
  bucket = "$INFLUXDB_BUCKET"
  timeout = "3s"

[[inputs.vsphere]]
  vcenters = [ "$VSHERE_URL" ]
  username = "$VSHERE_USERNAME"
  password = "$VSHERE_PASSWORD"
  insecure_skip_verify = true
  vm_metric_include = [
    "cpu.demand.average",
    "cpu.idle.summation",
    "cpu.latency.average",
    "cpu.readiness.average",
    "cpu.ready.summation",
    "cpu.run.summation",
    "cpu.usagemhz.average",
    "cpu.used.summation",
    "cpu.wait.summation",
    "mem.active.average",
    "mem.granted.average",
    "mem.latency.average",
    "mem.swapin.average",
    "mem.swapinRate.average",
    "mem.swapout.average",
    "mem.swapoutRate.average",
    "mem.usage.average",
    "mem.vmmemctl.average",
    "net.bytesRx.average",
    "net.bytesTx.average",
    "net.droppedRx.summation",
    "net.droppedTx.summation",
    "net.usage.average",
    "power.power.average",
    "virtualDisk.numberReadAveraged.average",
    "virtualDisk.numberWriteAveraged.average",
    "virtualDisk.read.average",
    "virtualDisk.readOIO.latest",
    "virtualDisk.throughput.usage.average",
    "virtualDisk.totalReadLatency.average",
    "virtualDisk.totalWriteLatency.average",
    "virtualDisk.write.average",
    "virtualDisk.writeOIO.latest",
    "sys.uptime.latest",
  ]

  host_metric_include = [
    "cpu.coreUtilization.average",
    "cpu.costop.summation",
    "cpu.demand.average",
    "cpu.idle.summation",
    "cpu.latency.average",
    "cpu.readiness.average",
    "cpu.ready.summation",
    "cpu.swapwait.summation",
    "cpu.usage.average",
    "cpu.usagemhz.average",
    "cpu.used.summation",
    "cpu.utilization.average",
    "cpu.wait.summation",
    "disk.deviceReadLatency.average",
    "disk.deviceWriteLatency.average",
    "disk.kernelReadLatency.average",
    "disk.kernelWriteLatency.average",
    "disk.numberReadAveraged.average",
    "disk.numberWriteAveraged.average",
    "disk.read.average",
    "disk.totalReadLatency.average",
    "disk.totalWriteLatency.average",
    "disk.write.average",
    "mem.active.average",
    "mem.latency.average",
    "mem.state.latest",
    "mem.swapin.average",
    "mem.swapinRate.average",
    "mem.swapout.average",
    "mem.swapoutRate.average",
    "mem.totalCapacity.average",
    "mem.usage.average",
    "mem.vmmemctl.average",
    "net.bytesRx.average",
    "net.bytesTx.average",
    "net.droppedRx.summation",
    "net.droppedTx.summation",
    "net.errorsRx.summation",
    "net.errorsTx.summation",
    "net.usage.average",
    "power.power.average",
    "storageAdapter.numberReadAveraged.average",
    "storageAdapter.numberWriteAveraged.average",
    "storageAdapter.read.average",
    "storageAdapter.write.average",
    "sys.uptime.latest",
  ]

  datacenter_metric_include = []
  datacenter_metric_exclude = [ "*" ]
EOF
