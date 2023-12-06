# GrafanaTelegrafInfluxDB: Monitoring vSphere

This repository provides a comprehensive guide for monitoring vSphere using Grafana, Telegraf, and InfluxDB. It includes detailed instructions on setting up and configuring these tools to effectively monitor your vSphere environment.

## Credits

The inspiration for this amazing dashboard comes from [Jorge de la Cruz's GitHub repository](https://github.com/jorgedlcruz/vmware-grafana). Full credits for the original dashboard concept and design go to this resource.

## Prerequisites

Before you begin, ensure the following setup steps are completed:

1. **New Disk Preparation**: Set up a new disk `sdb` on your system.
2. **Configuration File**: Modify the values in `config.txt` according to your setup requirements.
3. **Docker Images**: Download and store the following docker images in a folder named `images`:
   - `grafana-latest.tar`
   - `influxdb-2.0.tar`
   - `nginx-latest.tar`
   - `telegraf-latest.tar`

   Note: If these images are not stored as specified, the script may fail. Alternatively, you can modify the container loading section in `container_deploy.bash`.
4. **Active Directory Setup**: Create a user and define paths to Active Directory groups and users as required.
5. **Data Source Naming**: Change the data source name from `InfluxDBGrafana` to your preferred name in all JSON files (Overview, VMs, Hosts, Datastore).

## Usage Instructions

To set up and run the monitoring system, follow these steps:

1. **Clone and Prepare**:
   - Clone this repository or copy the files into a directory on your Linux machine.
   - Edit the files as per the prerequisites.

2. **Deployment**:
   - Run the following command in your terminal:
     ```bash
     bash deploy.bash
     ```
   - Enter your password when prompted for sudo permissions.
   - Wait for the process to complete, and your monitoring system should be up and running.

3. **Restarting or Reinstalling**:
   - If you need to stop the system and start over, execute the following commands:
     ```bash
     podman stop $(podman ps -aq) && \
     podman rm -f $(podman ps -aq) && \
     podman network rm influxdb-telegraf-net
     podman volume rm grafana-storage
     ```

## Support

For any issues or support requests, please file an issue on this GitHub repository. Your contributions and feedback are welcome to improve this project.

---

Thank you for using GrafanaTelegrafInfluxDB for monitoring your vSphere environment! 🚀

if you want to delete and start over
```bash
podman stop $(podman ps -aq) && \
podman rm -f $(podman ps -aq) && \
podman network rm influxdb-telegraf-net
podman volume rm grafana-storage
```
