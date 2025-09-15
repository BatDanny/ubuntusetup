#!/bin/bash

# ==================================================================================
# SCRIPT 1 of 2: DRIVER & KERNEL MODULE PREPARATION (v7)
# ==================================================================================
# This script installs all hardware drivers (NVIDIA, Motherboard Sensors) and
# configures the system to load them. It is idempotent and safe to re-run.
# A reboot is MANDATORY after this script completes successfully.
# ==================================================================================

set -e
if [[ $EUID -ne 0 ]]; then
   echo "This script must be run as root. Please use 'sudo ./01-prepare-drivers.sh'"
   exit 1
fi

REAL_USER="${SUDO_USER:-$(logname)}"
USER_HOME=$(getent passwd "$REAL_USER" | cut -d: -f6)
LOG_FILE="${USER_HOME}/setup_log_01_drivers_$(date +%F_%H-%M-%S).log"
exec &> >(tee -a "$LOG_FILE")

echo "--- [SCRIPT 1/2] Driver setup starting at $(date) ---"
echo "--- All output is being logged to: $LOG_FILE ---"

# --- STAGE 1: SYSTEM PREPARATION ---
echo " "
echo ">>> [1/3] Updating system, cleaning up old packages, and enabling 'universe' repository..."
apt-get update
apt-get upgrade -y
apt-get autoremove -y
apt-get install -y software-properties-common
add-apt-repository universe -y
apt-get update

# --- STAGE 2: NVIDIA DRIVER INSTALLATION ---
echo " "
echo ">>> [2/3] Installing NVIDIA Drivers and Settings Panel..."
add-apt-repository ppa:graphics-drivers/ppa -y
apt-get update

LATEST_DRIVER_PKG=$(apt-cache search --names-only '^nvidia-driver-[0-9]+$' | sort -V | tail -n 1 | awk '{print $1}')

if [ -z "$LATEST_DRIVER_PKG" ]; then
    echo "ERROR: Could not find any 'nvidia-driver-XXX' packages from the PPA."
    exit 1
else
    echo "--- Found latest available driver package: $LATEST_DRIVER_PKG ---"
    apt-get install -y "$LATEST_DRIVER_PKG" nvidia-settings
fi

# --- STAGE 3: MOTHERBOARD SENSOR DRIVER INSTALLATION ---
echo " "
echo ">>> [3/3] Installing Motherboard Sensor Drivers (it87)..."
echo "--- Blacklisting the generic nct6775 driver to prevent conflicts... ---"
{
    echo '# Prevent nct6775 from loading, as it conflicts with the it87 driver.'
    echo 'blacklist nct6775'
} | tee /etc/modprobe.d/blacklist-nct6775.conf

echo "--- Installing prerequisites for sensor drivers... ---"
apt-get install -y git dkms linux-headers-$(uname -r)

echo "--- Cloning and installing the it87 driver via DKMS... ---"
DEV_DIR="${USER_HOME}/dev"
mkdir -p "$DEV_DIR"
chown "$REAL_USER":"$REAL_USER" "$DEV_DIR"
cd "$DEV_DIR"
if [ -d "it87" ]; then
    rm -rf it87
fi
sudo -u "$REAL_USER" git clone https://github.com/frankcrawford/it87.git
cd it87

echo "--- Ensuring a clean slate by removing any pre-existing it87 DKMS module... ---"
# This command uses the project's own makefile to remove, which is the most reliable way.
# '|| true' ensures the script doesn't fail if the module wasn't already installed.
make dkms-remove || true

echo "--- Building and installing the it87 DKMS module... ---"
make dkms

echo "--- Configuring kernel modules to load on boot... ---"
{
    echo '# Load AMD CPU sensor module'
    echo 'k10temp'
    echo '# Load motherboard sensor module'
    echo 'it87'
} | tee /etc/modules-load.d/custom-sensors.conf

# --- FINALIZATION ---
echo " "
echo "================================================================="
echo "    SCRIPT 1 (DRIVER PREPARATION) IS COMPLETE!    "
echo "================================================================="
echo "!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!"
echo "    >>> ACTION REQUIRED: A FULL REBOOT IS MANDATORY <<<"
echo "!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!"
echo "The system is now prepared. A reboot is required to load the new"
echo "NVIDIA drivers and activate the sensor module blacklist."
echo ""
echo "Run the command: sudo reboot"
echo ""
echo "After rebooting, run the second script: sudo ./02-configure-software.sh"
echo "!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!"
