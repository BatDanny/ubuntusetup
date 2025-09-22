#!/bin/bash

# This script stops the GNOME Display Manager (GDM) to allow for
# manual installation or modification of graphics drivers.

echo "Attempting to stop the GNOME Display Manager (gdm)..."

# Stop the gdm service
systemctl stop gdm

# Check the exit status of the last command to confirm success
if [ $? -eq 0 ]; then
    echo "GDM service stopped successfully."
    echo "You can now run the NVIDIA installer."
else
    echo "Error: Failed to stop the GDM service."
    echo "You might need to check the service status with 'systemctl status gdm'."
    exit 1
fi

exit 0
