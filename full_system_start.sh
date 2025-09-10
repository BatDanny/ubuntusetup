#!/bin/bash

# ==================================================================================
# DEFINITIVE MASTER SCRIPT v6.9 for Ubuntu Server 24.04 + KDE Plasma Rig
# ==================================================================================
# This script automates the entire desktop setup process.
# v6.9 adds the 'nvtop' utility for real-time GPU monitoring.
# ==================================================================================

# --- PRE-FLIGHT CHECKS AND SETUP ---
set -e
if [[ $EUID -ne 0 ]]; then
   echo "This script must be run as root. Please use 'sudo ./your_script_name.sh'" 
   exit 1
fi

LOG_FILE="/home/${SUDO_USER:-$(logname)}/setup_log_$(date +%F_%H-%M-%S).log"
exec &> >(tee -a "$LOG_FILE")

echo "--- Full system setup starting at $(date) ---"
echo "--- All output is being logged to: $LOG_FILE ---"
START_SECONDS=$(date +%s)

# --- STAGE 1: ENABLE UNIVERSE REPOSITORY ---
echo " "
echo ">>> [1/13] Enabling the 'universe' repository..."
apt-get update
apt-get install -y software-properties-common
add-apt-repository universe -y
apt-get update

# --- STAGE 2: CORE DESKTOP INSTALLATION ---
echo " "
echo ">>> [2/13] Installing the minimal KDE Plasma Desktop..."
apt-get upgrade -y
apt-get install -y kde-plasma-desktop sddm konsole

# --- STAGE 3: SET SYSTEM TO BOOT TO GRAPHICAL MODE ---
echo " "
echo ">>> [3/13] Setting the system to boot into the graphical desktop..."
systemctl set-default graphical.target

# --- STAGE 4: CONFIGURE NETWORK MANAGEMENT FOR DESKTOP ---
echo " "
echo ">>> [4/13] Handing network control over to NetworkManager for GUI..."
echo '
# Let NetworkManager manage all devices on this system
network:
  version: 2
  renderer: NetworkManager
' | tee /etc/netplan/99-network-manager.yaml
netplan apply

# --- STAGE 5: SYSTEM FIXES AND CONFIGURATION ---
echo " "
echo ">>> [5/13] Applying fixes for Ubuntu 24.04 + KDE..."
apt-get remove -y qml-module-qtquick-virtualkeyboard || true # Continue if already removed
apt-get install -y kde-config-sddm

# --- STAGE 6: ESSENTIAL UTILITIES (Network, Browser, VNC) ---
echo " "
echo ">>> [6/13] Installing Network Manager Applet, Firefox, and TigerVNC..."
apt-get install -y plasma-nm tigervnc-viewer
add-apt-repository ppa:mozillateam/ppa -y
echo '
Package: *
Pin: release o=LP-PPA-mozillateam
Pin-Priority: 1001
' | tee /etc/apt/preferences.d/mozilla-firefox
apt-get update
apt-get install -y firefox

# --- STAGE 7: CORE DEVELOPMENT & MONITORING TOOLS ---
echo " "
echo ">>> [7/13] Installing Essential Development & Monitoring Tools..."
apt-get install -y build-essential git python3-pip python3-venv cmake lm-sensors

# --- STAGE 8: HARDWARE MONITORING CONFIGURATION ---
echo " "
echo ">>> [8/13] Configuring kernel modules for hardware monitoring..."
if ! grep -q "^k10temp" /etc/modules; then
    echo 'k10temp' | tee -a /etc/modules
    echo "Added k10temp module to /etc/modules for AMD CPU temperature monitoring."
fi

# --- STAGE 9: ZSH + OH MY ZSH SHELL ENVIRONMENT SETUP (IDEMPOTENT) ---
echo " "
echo ">>> [9/13] Setting up Zsh and Oh My Zsh..."
apt-get install -y zsh
if [ -n "$SUDO_USER" ]; then
    OH_MY_ZSH_DIR="/home/$SUDO_USER/.oh-my-zsh"
    ZSHRC_FILE="/home/$SUDO_USER/.zshrc"

    if [ -d "$OH_MY_ZSH_DIR" ]; then
        echo "Oh My Zsh is already installed for user: $SUDO_USER. Skipping installation."
    else
        echo "Installing Oh My Zsh for user: $SUDO_USER"
        sudo -u $SUDO_USER git clone https://github.com/ohmyzsh/ohmyzsh.git "$OH_MY_ZSH_DIR"
        sudo -u $SUDO_USER cp "$OH_MY_ZSH_DIR/templates/zshrc.zsh-template" "$ZSHRC_FILE"
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
' | sudo -u $SUDO_USER tee -a "$ZSHRC_FILE"
    fi
    
    if [ "$(getent passwd $SUDO_USER | cut -d: -f7)" != "$(which zsh)" ]; then
        echo "Setting Zsh as the default shell for $SUDO_USER..."
        sudo chsh -s $(which zsh) $SUDO_USER
    else
        echo "Zsh is already the default shell for $SUDO_USER."
    fi
fi

# --- STAGE 10: NVIDIA HOST DRIVER INSTALLATION ---
echo " "
echo ">>> [10/13] Installing NVIDIA Host Graphics Drivers..."
add-apt-repository ppa:graphics-drivers/ppa -y
dpkg --add-architecture i386
apt-get update
ubuntu-drivers autoinstall

# --- STAGE 11: GAMING ENVIRONMENT SETUP ---
echo " "
echo ">>> [11/13] Installing Core Gaming Software..."
apt-get install -y \
    wine64 \
    wine32 \
    steam \
    steam-devices \
    gamemode \
    mangohud \
    goverlay \
    nvtop
    # The following packages are commented out as they were not found in the
    # standard Ubuntu 24.04 repositories during the last test run.
    # heroic \
    # protonup-qt

# --- STAGE 12: DOCKER AND NVIDIA GPU CONTAINER SUPPORT ---
echo " "
echo ">>> [12/13] Installing Docker and NVIDIA Container Toolkit..."
apt-get install -y ca-certificates curl
install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
chmod a+r /etc/apt/keyrings/docker.asc
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu \
  $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
  tee /etc/apt/sources.list.d/docker.list > /dev/null
apt-get update
apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
if [ -n "$SUDO_USER" ]; then
    usermod -aG docker $SUDO_USER
fi

# Install NVIDIA Container Toolkit (Robust Method)
curl -fsSL https://nvidia.github.io/libnvidia-container/gpgkey | gpg --dearmor -o /usr/share/keyrings/nvidia-container-toolkit-keyring.gpg
curl -s -L https://nvidia.github.io/libnvidia-container/stable/deb/nvidia-container-toolkit.list | \
  sed 's#deb https://#deb [signed-by=/usr/share/keyrings/nvidia-container-toolkit-keyring.gpg] https://#g' | \
  tee /etc/apt/sources.list.d/nvidia-container-toolkit.list
apt-get update
apt-get install -y nvidia-container-toolkit
nvidia-ctk runtime configure --runtime=docker
systemctl restart docker

# --- STAGE 13: APPLY PERSONALIZED THEMES AND APPEARANCE ---
echo " "
echo ">>> [13/13] Installing and Applying Your Personal Themes..."
apt-get install -y sddm-theme-elarun
mkdir -p /etc/sddm.conf.d
echo "---
[Theme]
Current=elarun
" | tee /etc/sddm.conf.d/theme.conf
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

# --- FINALIZATION ---
echo " "
echo "================================================================="
echo "    COMPLETE PERSONALIZED SETUP IS FINISHED!    "
echo "================================================================="
END_SECONDS=$(date +%s)
DURATION=$((END_SECONDS - START_SECONDS))
MINUTES=$((DURATION / 60))
SECONDS_REMAINING=$((DURATION % 60))
echo "Total execution time: ${MINUTES} minutes and ${SECONDS_REMAINING} seconds."
echo "The full installation log has been saved to: $LOG_FILE"
echo ""
echo ">>> [CRITICAL FINAL STEP] PROPERLY CONFIGURE HARDWARE SENSORS <<<"
echo "To ensure your B650 chipset and all other hardware sensors are fully detected,"
echo "you must run the following interactive command now. This will allow tools"
echo "like MangoHud and System Monitor to show all available temperatures and fan speeds."
echo ""
echo "Run this command:"
echo "    sudo sensors-detect"
echo ""
echo "It is safe to answer YES (by typing 'yes' and pressing Enter) to all questions."
echo "This will ensure the necessary kernel modules are loaded on the next boot."
echo ""
echo "After running sensors-detect, a full reboot is required."
echo "Run the command: sudo reboot"
