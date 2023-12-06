#!/bin/bash

# Load environment variables from .env file
source "$(dirname "$0")/../config.txt"

# Update sysctl configuration for unprivileged ports and apply changes
echo "net.ipv4.ip_unprivileged_port_start=80" | sudo tee -a /etc/sysctl.conf && sudo sysctl --system

# Enable automatic container restart after reboot
systemctl --user enable podman-restart
loginctl enable-linger $USER

# Create XFS filesystem
sudo mkfs.xfs /dev/sdb
sudo mkdir /data
UUID=$(sudo blkid -o value -s UUID /dev/sdb)
echo "UUID=$UUID /data xfs defaults 0 2" | sudo tee -a /etc/fstab
sudo mount /dev/sdb /data
sudo mkdir -p /data/{influxdb,telegraf,grafana/storage,nginx/conf} && sudo chmod -R 777 /data
sudo chown -R $USER:$USER /data
sudo chown -R 472:472 /data/grafana


# Configure firewall
sudo firewall-cmd --permanent --add-port=8086/tcp --add-port=80/tcp --add-port=3000/tcp && sudo firewall-cmd --reload