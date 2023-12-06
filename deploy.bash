#!/bin/bash

# Load variables from a configuration file
source "$(dirname "$0")/config.txt"
SCRIPT_DIR=$(dirname "$0")

# Execute the system configuration script.
bash $SCRIPT_DIR/scripts/config_system.bash

# Generate files for the containers.
bash $SCRIPT_DIR/scripts/generate_files.bash

# Execute the container deployment script.
bash $SCRIPT_DIR/scripts/container_deploy.bash

# Execute the container configuration script.
bash $SCRIPT_DIR/scripts/config_containers.bash