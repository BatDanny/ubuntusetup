#!/bin/bash

# This script installs a full suite of essential desktop applications and utilities
# for a KDE Plasma environment built on Ubuntu Server (Corrected for 24.04).

# Exit immediately if a command exits with a non-zero status.
set -e

echo "--- Starting Full Desktop Environment Setup ---"

# --- Pre-accept Microsoft EULA for fonts ---
echo ">>> Pre-accepting EULA for Microsoft Fonts..."
echo ttf-mscorefonts-installer msttcorefonts/accepted-mscorefonts-eula select true | sudo debconf-set-selections

# --- Update Package Lists ---
echo " "
echo ">>> Updating package lists..."
sudo apt update

# --- 1. Install Essential Media & File Support ---
echo " "
echo ">>> Installing multimedia codecs, fonts, and archive tools..."
sudo apt install -y ubuntu-restricted-extras unrar p7zip-full

# --- 2. Install Graphical Software Center ---
echo " "
echo ">>> Installing the Discover software center..."
sudo apt install -y plasma-discover

# --- 3. Install Enhanced Hardware & Drive Support ---
echo " "
echo ">>> Installing Bluetooth and NTFS drive support..."
sudo apt install -y bluedevil ntfs-3g

# --- 4. Install System Monitoring & Firewall ---
echo " "
echo ">>> Installing system monitor and graphical firewall..."
sudo apt install -y plasma-systemmonitor gufw

# --- 5. Install a Full Office Suite ---
echo " "
echo ">>> Installing LibreOffice with KDE integration..."
# libreoffice-kf5: Installs the full LibreOffice suite and ensures it
# uses your KDE Frameworks 5 theme for a seamless look.
sudo apt install -y libreoffice-kf5

# --- 6. Install VLC Media Player ---
echo " "
echo ">>> Installing VLC..."
sudo apt install -y vlc

echo " "
echo "--- Desktop Setup Complete! ---"
echo "All selected applications have been installed."
echo "A reboot is recommended to ensure all new services and integrations are loaded correctly."
