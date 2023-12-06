#!/bin/bash

# Load environment variables from .env file
source "$(dirname "$0")/../config.txt"
PARENT_DIR="$(dirname "$0")/.."

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
DASHBOARD_JSON_PATHS=("$PARENT_DIR/json/Overview.json" "$PARENT_DIR/json/Datastore.json" "$PARENT_DIR/json/VMs.json" "$PARENT_DIR/json/Hosts.json")

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