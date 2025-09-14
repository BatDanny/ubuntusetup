#!/bin/bash

# ==================================================================================
# FINAL MASTER SCRIPT v4.1 for Ubuntu Server 24.04 + KDE Plasma Gaming & Docker Rig
# ==================================================================================
# This script automates the entire desktop setup process, including a full
# developer environment with Zsh, Oh My Zsh, Docker, and NVIDIA GPU support.
# v4.1 uses a more reliable 'git clone' method for Oh My Zsh installation.
# ==================================================================================

# Exit immediately if any command fails to prevent an incomplete setup.
set -e

echo "--- Starting Full System Configuration ---"
echo "You will be prompted for your password once."

# --- STAGE 1: CORE DESKTOP INSTALLATION ---
echo " "
echo ">>> [1/11] Installing the minimal KDE Plasma Desktop..."
sudo apt update
sudo apt upgrade -y
sudo apt install -y kde-plasma-desktop sddm konsole

# --- STAGE 2: SET SYSTEM TO BOOT TO GRAPHICAL MODE ---
echo " "
echo ">>> [2/11] Setting the system to boot into the graphical desktop..."
sudo systemctl set-default graphical.target

# --- STAGE 3: SYSTEM FIXES AND CONFIGURATION ---
echo " "
echo ">>> [3/11] Applying fixes for Ubuntu 24.04 + KDE..."
sudo apt remove -y qml-module-qtquick-virtualkeyboard
sudo apt install -y kde-config-sddm

# --- STAGE 4: ESSENTIAL UTILITIES (Network & Browser) ---
echo " "
echo ">>> [4/11] Installing Network Manager and Firefox..."
sudo apt install -y plasma-nm
sudo add-apt-repository ppa:mozillateam/ppa -y
echo '
Package: *
Pin: release o=LP-PPA-mozillateam
Pin-Priority: 1001
' | sudo tee /etc/apt/preferences.d/mozilla-firefox
sudo apt update
sudo apt install -y firefox

# --- STAGE 5: CORE DEVELOPMENT TOOLS ---
echo " "
echo ">>> [5/11] Installing Essential Development Tools..."
sudo apt install -y build-essential git python3-pip python3-venv cmake

# --- STAGE 6: ZSH + OH MY ZSH SHELL ENVIRONMENT SETUP (ROBUST METHOD) ---
echo " "
echo ">>> [6/11] Setting up Zsh and Oh My Zsh..."
sudo apt install -y zsh
if [ -n "$SUDO_USER" ]; then
    echo "Installing Oh My Zsh for user: $SUDO_USER"
    # Clone the repository directly to avoid unreliable curl to raw.githubusercontent.com
    sudo -u $SUDO_USER git clone https://github.com/ohmyzsh/ohmyzsh.git /home/$SUDO_USER/.oh-my-zsh
    
    # Create the .zshrc file from the template
    sudo -u $SUDO_USER cp /home/$SUDO_USER/.oh-my-zsh/templates/zshrc.zsh-template /home/$SUDO_USER/.zshrc
    
    # Set Zsh as the default shell for the user
    sudo chsh -s $(which zsh) $SUDO_USER
    
    # Append custom paths and aliases to the .zshrc file
    ZSHRC_FILE="/home/$SUDO_USER/.zshrc"
    echo '
# --------------------------------------------------------------------
# CUSTOM CONFIGURATION ADDED BY SETUP SCRIPT
# --------------------------------------------------------------------

# Add user-specific bin directory (for pip, etc.) to the PATH
export PATH="$HOME/.local/bin:$PATH"

# Add other common paths (e.g., for Go, if you install it)
# export PATH="$HOME/go/bin:$PATH"

# Useful Aliases
alias ll="ls -alF"
alias la="ls -A"
alias l="ls -CF"
alias ..="cd .."
alias docker-clean="docker system prune -a --volumes"

# --------------------------------------------------------------------
' | sudo -u $SUDO_USER tee -a $ZSHRC_FILE
else
    echo "Warning: Could not determine user to set up Zsh for. Skipping."
fi

# --- STAGE 7: NVIDIA HOST DRIVER INSTALLATION ---
echo " "
echo ">>> [7/11] Installing NVIDIA Host Graphics Drivers..."
sudo add-apt-repository ppa:graphics-drivers/ppa -y
sudo add-apt-repository ppa:kisak/kisak-fresh -y
sudo dpkg --add-architecture i386
sudo apt update
sudo ubuntu-drivers autoinstall

# --- STAGE 8: GAMING ENVIRONMENT SETUP ---
echo " "
echo ">>> [8/11] Installing Core Gaming Software..."
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

# --- STAGE 9: DOCKER AND NVIDIA GPU CONTAINER SUPPORT ---
echo " "
echo ">>> [9/11] Installing Docker and NVIDIA Container Toolkit..."
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
curl -fsSL https://nvidia.github.io/libnvidia-container/gpgkey | sudo gpg --dearmor -o /usr/share/keyrings/nvidia-container-toolkit-keyring.gpg \
  && curl -s -L https://nvidia.github.io/libnvidia-container/stable/deb/nvidia-container-toolkit.list | \
    sed 's#deb https://#deb [signed-by=/usr/share/keyrings/nvidia-container-toolkit-keyring.gpg] https://#g' | \
    sudo tee /etc/apt/sources.list.d/nvidia-container-toolkit.list
sudo apt-get update
sudo apt-get install -y nvidia-container-toolkit
sudo systemctl restart docker

# --- STAGE 10: APPLY PERSONALIZED THEMES AND APPEARANCE ---
echo " "
echo ">>> [10/11] Installing and Applying Your Personal Themes..."
sudo apt install -y sddm-theme-sugar-candy
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

# --- STAGE 11: FINAL CLEANUP ---
echo " "
echo ">>> [11/11] Performing final cleanup..."
sudo apt autoremove -y

echo " "
echo "================================================================="
echo "    COMPLETE PERSONALIZED SETUP IS FINISHED!    "
echo "================================================================="
echo "A full reboot is required to apply all changes."
echo "After rebooting, open a new terminal to start using Zsh."
echo "Run the command: sudo reboot"
