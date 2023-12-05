#!/bin/bash

# Load environment variables from .env file
CONFIG_FILE="/home/tmgvr/script/config.txt"
source "$CONFIG_FILE"

# Update /etc/sysctl.conf
echo "net.ipv4.ip_unprivileged_port_start=80" | sudo tee -a /etc/sysctl.conf

# Apply the changes
sudo sysctl --system

# Containers will start after reboot
systemctl --user enable podman-restart
loginctl enable-linger $user

# Create XFS filesystem
sudo mkfs.xfs /dev/sdb
sudo mkdir /data
UUID=$(sudo blkid -o value -s UUID /dev/sdb)
echo "UUID=$UUID /data xfs defaults 0 2" | sudo tee -a /etc/fstab
sudo mount /dev/sdb /data
sudo mkdir -p /data/{influxdb,telegraf,grafana/storage,nginx/conf} && sudo chmod -R 777 /data
sudo chown -R tmgvr:tmgvr /data
sudo chown -R 472:472 /data/grafana


# Configure firewall
sudo firewall-cmd --permanent --add-port=8086/tcp --add-port=80/tcp --add-port=3000/tcp && sudo firewall-cmd --reload

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

# Generate grafana configuration file
cat <<EOF > /data/grafana/grafana.ini
[auth.ldap]
enabled = true
config_file = /etc/grafana/ldap.toml
allow_sign_up = true
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
  timeout = "0s"

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

# Load the docker/podman images
podman load < /home/tmgvr/script/images/nginx-latest.tar
podman load < /home/tmgvr/script/images/telegraf-latest.tar
podman load < /home/tmgvr/script/images/influxdb-2.0.tar
podman load < /home/tmgvr/script/images/grafana-latest.tar

# Create Docker volumes and network
podman network create --driver bridge influxdb-telegraf-net

# Run nginx container
podman run -d \
  --restart=always \
  --name nginx-proxy \
  -p 80:80 \
  -v /data/nginx/conf/nginx.conf:/etc/nginx/nginx.conf:ro \
  --privileged \
  nginx:latest

# Run InfluxDB container
podman run -d --name=influxdb \
  --restart=always \
  -p 8086:8086 \
  -v /data/influxdb:/root/.influxdb2 \
  --net=influxdb-telegraf-net \
  influxdb:2.0

# Run Grafana container
podman run -d -p 3000:3000 --name=grafana \
  --restart=always \
  --volume "/data/grafana/storage:/var/lib/grafana" \
  --volume "/data/grafana/grafana.ini:/etc/grafana/grafana.ini" \
  --volume "/data/grafana/ldap.toml:/etc/grafana/ldap.toml" \
  -e "GF_AUTH_LDAP_ENABLED=true" \
  -e "GF_AUTH_LDAP_CONFIG_FILE=/etc/grafana/ldap.toml" \
  -e "GF_SECURITY_ADMIN_USER=${GRAFANA_ADMIN_USER}" \
  -e "GF_SECURITY_ADMIN_PASSWORD=${GRAFANA_ADMIN_PASSWORD}" \
  --privileged \
  grafana/grafana:latest


# Run Telegraf container
podman run -d --name=telegraf \
  --restart=always \
  -v /data/telegraf/telegraf.conf:/etc/telegraf/telegraf.conf:ro \
  --net=influxdb-telegraf-net \
  --privileged \
  telegraf:latest

sleep 60

# Configure InfluxDB
podman exec -it influxdb influx setup \
  --org "$INFLUXDB_ORG_NAME" \
  --bucket "$INFLUXDB_BUCKET" \
  --username "$INFLUXDB_USERNAME" \
  --password "$INFLUXDB_PASSWORD" \
  --token "$INFLUXDB_TOKEN" \
  --force

sleep 60

curl -X POST "$GRAFANA_URL/api/datasources" \
    -H "Content-Type: application/json" \
    -H "Authorization: Basic $(echo -n "$GRAFANA_ADMIN_USER:$GRAFANA_ADMIN_PASSWORD" | base64)" \
    -d '{
          "name": "'$DATASOURCE_NAME'",
          "type": "influxdb",
          "access": "proxy",
          "url": "'$INFLUXDB_URL'",
          "basicAuth": true,
          "basicAuthUser": "'$INFLUXDB_USERNAME'",
          "basicAuthPassword": "'$INFLUXDB_PASSWORD'",
          "jsonData": {
             "httpMode": "POST",
             "organization": "'$INFLUXDB_ORG_NAME'",
             "defaultBucket": "'$INFLUXDB_BUCKET'",
             "version": "Flux",
             "tlsAuth": false,
             "tlsAuthWithCACert": false,
             "tlsSkipVerify": true
          },
          "secureJsonData": {
            "basicAuthPassword": "'$INFLUXDB_PASSWORD'",
            "token": "'$INFLUXDB_TOKEN'"
          }
       }'

sleep 5

# Array of JSON dashboard paths
DASHBOARD_JSON_PATHS=("/home/tmgvr/script/json/Overview.json" "/home/tmgvr/script/json/Datastore.json" "/home/tmgvr/script/json/VMs.json" "/home/tmgvr/script/json/Hosts.json")

# Loop through each dashboard file and upload
for DASHBOARD_JSON_PATH in "${DASHBOARD_JSON_PATHS[@]}"; do
    if [[ -f "$DASHBOARD_JSON_PATH" ]]; then
        # Read the JSON file
        DASHBOARD_JSON=$(<"$DASHBOARD_JSON_PATH")

        # Make the POST request to Grafana
        RESPONSE=$(curl -s -k -X POST "$GRAFANA_URL/api/dashboards/db" \
            -u "$GRAFANA_ADMIN_USER:$GRAFANA_ADMIN_PASSWORD" \
            -H "Content-Type: application/json" \
            -d "{\"dashboard\":$DASHBOARD_JSON,\"overwrite\":false}")

        # Check response
        if [[ $RESPONSE == *"\"status\":\"success\""* ]]; then
            echo "Dashboard $DASHBOARD_JSON_PATH uploaded successfully."
        else
            echo "Failed to upload dashboard $DASHBOARD_JSON_PATH."
            echo "Response: $RESPONSE"
        fi
    else
        echo "Dashboard file $DASHBOARD_JSON_PATH not found."
    fi
done
