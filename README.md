# GrafanaTelegrafInfluxDB
Monitoring vSphere with Grafana Telegraf and InfluxDB

All credits for the amazing dashboard go to https://github.com/jorgedlcruz/vmware-grafana !

Prerequisites:
- Create a new disk sdb.
- Change the values in the config.txt file.
- You must download and save the docker images into a folder called images, which goes by the names:
  grafana-latest.tar
  influxdb-2.0.tar
  nginx-latest.tar
  telegraf-latest.tar
  if you do not do this the script will not work / You can change the part of the load containers in the container_deploy.bash file
- Create user and the paths to the Active Directory groups and user
- You will have to change from InfluxDBGrafana to whatever Data Source name you want to use you have to do that on all of the json files (Overview, VMs, Hosts, Datastore)


Usage:
copy the files into a folder on your linux machine / git clone and edit them by the prerequisites steps
then do
```bash
bash deploy.bash
```
put your password for sudo permissions
wait and get it up and running

if you want to delete and start over
```bash
podman stop $(podman ps -aq) && \
podman rm -f $(podman ps -aq) && \
podman network rm influxdb-telegraf-net
podman volume rm grafana-storage
```
