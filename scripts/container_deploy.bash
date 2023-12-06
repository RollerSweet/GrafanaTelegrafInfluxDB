#!/bin/bash

# Load environment variables from .env file
source "$(dirname "$0")/../config.txt"
PARENT_DIR="$(dirname "$0")/.."

# Load the docker/podman images
podman load < $PARENT_DIR/images/nginx-latest.tar
podman load < $PARENT_DIR/images/telegraf-latest.tar
podman load < $PARENT_DIR/images/influxdb-2.0.tar
podman load < $PARENT_DIR/images/grafana-latest.tar

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

# Run InfluxDB container
podman run -d --name=influxdb \
  --restart=always \
  -p 8086:8086 \
  -v /data/influxdb:/root/.influxdb2 \
  --net=influxdb-telegraf-net \
  influxdb:2.0
  
sleep 30

# Configure InfluxDB
podman exec -it influxdb influx setup \
  --org "$INFLUXDB_ORG_NAME" \
  --bucket "$INFLUXDB_BUCKET" \
  --username "$INFLUXDB_USERNAME" \
  --password "$INFLUXDB_PASSWORD" \
  --token "$INFLUXDB_TOKEN" \
  --force



# Run Telegraf container
podman run -d --name=telegraf \
  --restart=always \
  -v /data/telegraf/telegraf.conf:/etc/telegraf/telegraf.conf:ro \
  --net=influxdb-telegraf-net \
  --privileged \
  telegraf:latest

sleep 30
