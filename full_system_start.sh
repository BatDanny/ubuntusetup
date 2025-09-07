#!/bin/bash

# ==================================================================================
# FINAL MASTER SCRIPT v5.1 for Ubuntu Server 24.04 + KDE Plasma Gaming & Docker Rig
# ==================================================================================
# This script automates the entire desktop setup process with a focus on
# resilience and diagnostics.
#
# KEY FEATURES:
# - CONTINUES ON FAILURE: If a non-critical stage fails, it logs a warning
#   and proceeds to the next stage.
# - COMPREHENSIVE LOGGING: All output is saved to a timestamped log file
#   (e.g., setup_log_YYYY-MM-DD_HH-MM-SS.log) for easy troubleshooting.
# - SUDO CHECK: Exits gracefully if not run with root privileges.
# ==================================================================================

# --- PRE-FLIGHT CHECKS AND SETUP ---

# 1. Ensure the script is run as root/sudo
if [ "$EUID" -ne 0 ]; then
  echo "ERROR: This script must be run with sudo or as the root user."
  exit 1
fi

# 2. Setup Logging
LOG_FILE="setup_log_$(date +%Y-%m-%d_%H-%M-%S).log"
exec &> >(tee -a "$LOG_FILE")
echo "--- Full system setup starting at $(date) ---"
echo "--- All output is being logged to: ${LOG_FILE} ---"

# --- FUNCTION DEFINITIONS FOR EACH STAGE ---

run_stage() {
    local stage_name="$1"
    # Shift the arguments to pass the rest to the function
    shift
    local stage_function="$1"
    shift
    
    echo " "
    echo ">>> [STAGE] :: Starting: ${stage_name}..."
    # Execute the function with its arguments
    "$stage_function" "$@"
    
    if [ $? -ne 0 ]; then
        echo "!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!"
        echo "!!! WARNING: Stage '${stage_name}' encountered an error."
        echo "!!! The script will continue, but check the log for details."
        echo "!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!"
    else
        echo ">>> [STAGE] :: Completed: ${stage_name}."
    fi
}

install_core_desktop() {
    sudo apt update && sudo apt upgrade -y
    sudo apt install -y kde-plasma-desktop sddm konsole
}

set_boot_target() {
    sudo systemctl set-default graphical.target
}

apply_system_fixes() {
    sudo apt remove -y qml-module-qtquick-virtualkeyboard
    sudo apt install -y kde-config-sddm
}

install_utilities() {
    sudo apt install -y plasma-nm tigervnc-viewer
    sudo add-apt-repository ppa:mozillateam/ppa -y
    echo '
Package: *
Pin: release o=LP-PPA-mozillateam
Pin-Priority: 1001
' | sudo tee /etc/apt/preferences.d/mozilla-firefox
    sudo apt update
    sudo apt install -y firefox
}

install_dev_tools() {
    sudo apt install -y build-essential git python3-pip python3-venv cmake
}

setup_zsh() {
    sudo apt install -y zsh
    if [ -n "$SUDO_USER" ]; then
        sudo -u $SUDO_USER git clone https://github.com/ohmyzsh/ohmyzsh.git /home/$SUDO_USER/.oh-my-zsh
        sudo -u $SUDO_USER cp /home/$SUDO_USER/.oh-my-zsh/templates/zshrc.zsh-template /home/$SUDO_USER/.zshrc
        sudo chsh -s $(which zsh) $SUDO_USER
        ZSHRC_FILE="/home/$SUDO_USER/.zshrc"
        echo '
# --- CUSTOM CONFIGURATION FROM SETUP SCRIPT ---
export PATH="$HOME/.local/bin:$PATH"
alias ll="ls -alF"; alias la="ls -A"; alias l="ls -CF"; alias ..="cd .."; alias docker-clean="docker system prune -a --volumes";
' | sudo -u $SUDO_USER tee -a $ZSHRC_FILE
    fi
}

install_drivers() {
    sudo add-apt-repository ppa:graphics-drivers/ppa -y
    # This 'if' statement specifically handles the Kisak PPA failure.
    if ! sudo add-apt-repository ppa:kisak/kisak-fresh -y; then
        echo "Warning: Could not add Kisak PPA. Continuing with default Mesa drivers."
    fi
    sudo dpkg --add-architecture i386
    sudo apt update
    sudo ubuntu-drivers autoinstall
}

install_gaming_env() {
    sudo apt install -y wine64 wine32 steam steam-devices gamemode heroic protonup-qt mangohud goverlay
}

install_docker() {
    sudo apt-get install -y ca-certificates curl
    sudo install -m 0755 -d /etc/apt/keyrings
    sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
    sudo chmod a+r /etc/apt/keyrings/docker.asc
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
    sudo apt-get update
    sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
    if [ -n "$SUDO_USER" ]; then
        sudo usermod -aG docker $SUDO_USER
    fi
    curl -fsSL https://nvidia.github.io/libnvidia-container/gpgkey | sudo gpg --dearmor -o /usr/share/keyrings/nvidia-container-toolkit-keyring.gpg
    curl -s -L https://nvidia.github.io/libnvidia-container/stable/deb/nvidia-container-toolkit.list | sed 's#deb https://#deb [signed-by=/etc/apt/keyrings/nvidia-container-toolkit-keyring.gpg] https://#g' | sudo tee /etc/apt/sources.list.d/nvidia-container-toolkit.list
    sudo apt-get update
    sudo apt-get install -y nvidia-container-toolkit
    sudo systemctl restart docker
}

apply_themes() {
    sudo apt install -y sddm-theme-sugar-candy
    echo "[Theme]\nCurrent=Sugar-Candy" | sudo tee /etc/sddm.conf.d/theme.conf
    if [ -n "$SUDO_USER" ]; then
        sudo -u $SUDO_USER kwriteconfig5 --file ~/.config/kdeglobals --group General --key LookAndFeelPackage "org.kde.breezedark.desktop"
        sudo -u $SUDO_USER kwriteconfig5 --file ~/.config/plasmarc --group "Theme" --key "name" "Breeze-Dark"
        sudo -u $SUDO_USER kwriteconfig5 --file ~/.config/kdeglobals --group "KDE" --key "ColorScheme" "Breeze Dark"
        sudo -u $SUDO_USER kwriteconfig5 --file ~/.config/kwinrc --group org.kde.kdecoration2 --key theme "__aurorae__svg__Breeze"
        sudo -u $SUDO_USER kwriteconfig5 --file ~/.config/kdeglobals --group Icons --key Theme "breeze-dark"
        sudo -u $SUDO_USER kwriteconfig5 --file ~/.config/kcminputrc --group Mouse --key cursorTheme "breeze_cursors"
        sudo -u $SUDO_USER kwriteconfig5 --file ~/.config/ksplashrc --group KSplash --key Theme "org.kde.breeze.desktop"
    fi
}

final_cleanup() {
    sudo apt autoremove -y
}

# --- SCRIPT EXECUTION ---

# CRITICAL STAGE: Install Core Desktop. We will exit if this fails.
echo ">>> [CRITICAL STAGE] :: Starting: Core Desktop Installation..."
if ! install_core_desktop; then
    echo "!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!"
    echo "!!! CRITICAL ERROR: Failed to install the KDE Plasma Desktop."
    echo "!!! The script cannot continue. Please check the log for details."
    echo "!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!"
    exit 1
else
    echo ">>> [CRITICAL STAGE] :: Completed: Core Desktop Installation."
fi

# Resilient Stages: Run each stage and warn on failure.
run_stage "Set Boot Target" set_boot_target
run_stage "Apply System Fixes" apply_system_fixes
run_stage "Install Utilities" install_utilities
run_stage "Install Development Tools" install_dev_tools
run_stage "Setup Zsh & Oh My Zsh" setup_zsh
run_stage "Install Graphics Drivers" install_drivers
run_stage "Install Gaming Environment" install_gaming_env
run_stage "Install Docker & NVIDIA Support" install_docker
run_stage "Apply Personal Themes" apply_themes
run_stage "Final Cleanup" final_cleanup

echo " "
echo "================================================================="
echo "    COMPLETE PERSONALIZED SETUP IS FINISHED!    "
echo "================================================================="
echo "The full installation log has been saved to: ${LOG_FILE}"
echo "Please review it for any warnings or errors."
echo "A full reboot is required to apply all changes."
echo "Run the command: sudo reboot"

# --- SCRIPT METADATA ---
# Script Version: 5.1
# Last Updated: 2025-09-07 15:35:00 UTC
