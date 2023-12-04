# GrafanaTelegrafInfluxDB
Monitoring vSphere with Grafana Telegraf and InfluxDB

.env File
```bash
# InfluxDB Configuration
INFLUXDB_URL="http://Address:8086"
INFLUXDB_TOKEN="TamirHaGever"
INFLUXDB_ORG_NAME="vCenterOrg"
INFLUXDB_BUCKET="vCenterBucket"
INFLUXDB_USERNAME="admin"
INFLUXDB_PASSWORD="secret123"

# Grafana Configuration
GRAFANA_ADMIN_USER="admin"
GRAFANA_ADMIN_PASSWORD="Ultra123!"
GRAFANA_URL="http://Address:3000"
DATASOURCE_NAME="InfluxDBGrafana"

# vSphere Configuration for Telegraf
VSHERE_URL="https://vCenterAddress/sdk"
VSHERE_USERNAME="administrator@vsphere.local"
VSHERE_PASSWORD="secret123"

#nginx Configuration
HOST_IP="Address"
DOMAIN_NAME="domain.name"

```
if you want to delete and start over
```bash
podman stop $(podman ps -aq) && \
podman rm -f $(podman ps -aq) && \
podman network rm influxdb-telegraf-net
podman volume rm grafana-storage
```
