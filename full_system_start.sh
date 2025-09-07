#!/bin/bash

# ==================================================================================
# FINAL MASTER SCRIPT v5.0 for Ubuntu Server 24.04 + KDE Plasma Gaming & Docker Rig
# ==================================================================================
# This script automates the entire desktop setup process, including a full
# developer environment with Zsh, Oh My Zsh, Docker, and NVIDIA GPU support.
# v5.0 fixes all errors identified in the user-provided setup log.
# ==================================================================================

# Exit immediately if any command fails to prevent an incomplete setup.
set -e

echo "--- Starting Full System Configuration ---"
echo "You will be prompted for your password once."

# --- STAGE 1: ENABLE UNIVERSE REPOSITORY ---
echo " "
echo ">>> [1/12] Enabling the 'universe' repository for additional software..."
sudo apt update
sudo apt install -y software-properties-common
sudo add-apt-repository universe -y
sudo apt update

# --- STAGE 2: CORE DESKTOP INSTALLATION ---
echo " "
echo ">>> [2/12] Installing the minimal KDE Plasma Desktop..."
sudo apt upgrade -y
sudo apt install -y kde-plasma-desktop sddm konsole

# --- STAGE 3: SET SYSTEM TO BOOT TO GRAPHICAL MODE ---
echo " "
echo ">>> [3/12] Setting the system to boot into the graphical desktop..."
sudo systemctl set-default graphical.target

# --- STAGE 4: SYSTEM FIXES AND CONFIGURATION ---
echo " "
echo ">>> [4/12] Applying fixes for Ubuntu 24.04 + KDE..."
sudo apt remove -y qml-module-qtquick-virtualkeyboard
sudo apt install -y kde-config-sddm

# --- STAGE 5: ESSENTIAL UTILITIES (Network, Browser, VNC) ---
echo " "
echo ">>> [5/12] Installing Network Manager, Firefox, and TigerVNC..."
sudo apt install -y plasma-nm tigervnc-viewer
sudo add-apt-repository ppa:mozillateam/ppa -y
echo '
Package: *
Pin: release o=LP-PPA-mozillateam
Pin-Priority: 1001
' | sudo tee /etc/apt/preferences.d/mozilla-firefox
sudo apt update
sudo apt install -y firefox

# --- STAGE 6: CORE DEVELOPMENT TOOLS ---
echo " "
echo ">>> [6/12] Installing Essential Development Tools..."
sudo apt install -y build-essential git python3-pip python3-venv cmake

# --- STAGE 7: ZSH + OH MY ZSH SHELL ENVIRONMENT SETUP (ROBUST METHOD) ---
echo " "
echo ">>> [7/12] Setting up Zsh and Oh My Zsh..."
sudo apt install -y zsh
if [ -n "$SUDO_USER" ]; then
    echo "Installing Oh My Zsh for user: $SUDO_USER"
    sudo -u $SUDO_USER git clone https://github.com/ohmyzsh/ohmyzsh.git /home/$SUDO_USER/.oh-my-zsh
    sudo -u $SUDO_USER cp /home/$SUDO_USER/.oh-my-zsh/templates/zshrc.zsh-template /home/$SUDO_USER/.zshrc
    sudo chsh -s $(which zsh) $SUDO_USER
    ZSHRC_FILE="/home/$SUDO_USER/.zshrc"
    echo '
# --------------------------------------------------------------------
# CUSTOM CONFIGURATION ADDED BY SETUP SCRIPT
# --------------------------------------------------------------------
export PATH="$HOME/.local/bin:$PATH"
alias ll="ls -alF"
alias la="ls -A"
alias l="ls -CF"
alias ..="cd .."
alias docker-clean="docker system prune -a --volumes"
# --------------------------------------------------------------------
' | sudo -u $SUDO_USER tee -a $ZSHRC_FILE
fi

# --- STAGE 8: NVIDIA HOST DRIVER INSTALLATION ---
echo " "
echo ">>> [8/12] Installing NVIDIA Host Graphics Drivers..."
sudo add-apt-repository ppa:graphics-drivers/ppa -y
# REMOVED: Kisak PPA which is not available for Ubuntu 24.04.
sudo dpkg --add-architecture i386
sudo apt update
sudo ubuntu-drivers autoinstall

# --- STAGE 9: GAMING ENVIRONMENT SETUP ---
echo " "
echo ">>> [9/12] Installing Core Gaming Software..."
sudo apt install -y \
    wine64 \
    wine32 \
    steam \
    steam-devices \
    gamemode \
    heroic \
    protonup-qt \
    mangohud \
    goverlay

# --- STAGE 10: DOCKER AND NVIDIA GPU CONTAINER SUPPORT ---
echo " "
echo ">>> [10/12] Installing Docker and NVIDIA Container Toolkit..."
# Install Docker Engine
sudo apt-get install -y ca-certificates curl
sudo install -m 0755 -d /etc/apt/keyrings
sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
sudo chmod a+r /etc/apt/keyrings/docker.asc
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu \
  $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
  sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
sudo apt-get update
sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
if [ -n "$SUDO_USER" ]; then
    sudo usermod -aG docker $SUDO_USER
fi

# Install NVIDIA Container Toolkit (Robust Method)
sudo apt-get update
sudo apt-get install -y nvidia-container-toolkit
sudo nvidia-ctk runtime configure --runtime=docker
sudo systemctl restart docker

# --- STAGE 11: APPLY PERSONALIZED THEMES AND APPEARANCE ---
echo " "
echo ">>> [11/12] Installing and Applying Your Personal Themes..."
sudo apt install -y sddm-theme-sugar-candy
# FIX: Ensure the configuration directory exists before writing to it.
sudo mkdir -p /etc/sddm.conf.d
echo "---
[Theme]
Current=Sugar-Candy
" | sudo tee /etc/sddm.conf.d/theme.conf
if [ -n "$SUDO_USER" ]; then
    echo "Applying desktop themes for user: $SUDO_USER"
    sudo -u $SUDO_USER kwriteconfig5 --file ~/.config/kdeglobals --group General --key LookAndFeelPackage "org.kde.breezedark.desktop"
    sudo -u $SUDO_USER kwriteconfig5 --file ~/.config/plasmarc --group "Theme" --key "name" "Breeze-Dark"
    sudo -u $SUDO_USER kwriteconfig5 --file ~/.config/kdeglobals --group "KDE" --key "ColorScheme" "Breeze Dark"
    sudo -u $SUDO_USER kwriteconfig5 --file ~/.config/kwinrc --group org.kde.kdecoration2 --key theme "__aurorae__svg__Breeze"
    sudo -u $SUDO_USER kwriteconfig5 --file ~/.config/kdeglobals --group Icons --key Theme "breeze-dark"
    sudo -u $SUDO_USER kwriteconfig5 --file ~/.config/kcminputrc --group Mouse --key cursorTheme "breeze_cursors"
    sudo -u $SUDO_USER kwriteconfig5 --file ~/.config/ksplashrc --group KSplash --key Theme "org.kde.breeze.desktop"
fi

# --- STAGE 12: FINAL CLEANUP ---
echo " "
echo ">>> [12/12] Performing final cleanup..."
sudo apt autoremove -y

echo " "
echo "================================================================="
echo "    COMPLETE PERSONALIZED SETUP IS FINISHED!    "
echo "================================================================="
echo "A full reboot is required to apply all changes."
echo "After rebooting, open a new terminal to start using Zsh."
echo "Run the command: sudo reboot"
