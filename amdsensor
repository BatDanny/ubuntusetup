#!/bin/bash

# This script automates the installation of sensor drivers for a 
# Gigabyte B850 AI TOP motherboard on Ubuntu.

# --- Step 1: Install Prerequisites ---
echo "--- Installing prerequisite packages (git, dkms, kernel headers)... ---"
sudo apt-get update
sudo apt-get install -y git dkms linux-headers-generic

# --- Step 2: Download the Driver Source Code ---
echo "--- Cloning the it87 driver repository from GitHub... ---"
# Create a development directory if it doesn't exist
mkdir -p ~/dev
cd ~/dev
# Remove any old version of the directory to ensure a clean clone
rm -rf it87
git clone https://github.com/frankcrawford/it87.git

# --- Step 3: Build and Install the Driver using DKMS ---
echo "--- Building and installing the driver via DKMS... ---"
cd it87
sudo make dkms

# --- Step 4: Ensure Drivers Load on Boot ---
echo "--- Creating config file to load modules on boot... ---"
{
    echo '# Load AMD CPU sensor module'
    echo 'k10temp'
    echo '# Load motherboard sensor module'
    echo 'it87'
} | sudo tee /etc/modules-load.d/lm-sensors.conf

# --- Step 5: Load Drivers for the Current Session ---
echo "--- Loading drivers for the current session... ---"
sudo modprobe k10temp
sudo modprobe it87

# --- Final Confirmation ---
echo ""
echo "--- Installation complete! ---"
echo "Showing current sensor readings:"
sensors
