# GrafanaTelegrafInfluxDB
Monitoring vSphere with Grafana Telegraf and InfluxDB

.env File
```bash
INFLUXDB_URL="http://address:8086"
INFLUXDB_TOKEN="TamirHaGever"
INFLUXDB_ORG_NAME="TamirOrg"
INFLUXDB_BUCKET="TamirBucket"
INFLUXDB_USERNAME="admin"
INFLUXDB_PASSWORD="secret"
VSHERE_URL="https://address/sdk"
VSHERE_USERNAME="administrator@vsphere.local"
VSHERE_PASSWORD="secret"
GRAFANA_ADMIN_USER="admin"
GRAFANA_ADMIN_PASSWORD="secret"
GRAFANA_URL="http://address:3000"
DATASOURCE_NAME="MyInfluxDB"
```
if you want to delete and start over
```bash
podman stop $(podman ps -aq) && \
podman rm -f $(podman ps -aq) && \
podman network rm influxdb-telegraf-net
podman volume rm grafana-storage
```
