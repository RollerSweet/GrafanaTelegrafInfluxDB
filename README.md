# GrafanaTelegrafInfluxDB
Monitoring vSphere with Grafana Telegraf and InfluxDB

if you want to delete and start over
```bash
podman stop $(podman ps -aq) && \
podman rm -f $(podman ps -aq) && \
podman network rm influxdb-telegraf-net
podman volume rm grafana-storage
```
