#!/bin/bash

# ==================================================================================
# SCRIPT 2 of 2: SOFTWARE & SERVICES CONFIGURATION (v18 - FINAL, CORRECTED)
# ==================================================================================
# v17: Final failed attempt with gsettings.
# v18: DEFINITIVE FIX. This script ABANDONS all failed remote desktop configuration.
#      Its sole purpose is to correctly install all software packages and configure
#      the firewall. It then provides the user with the single, correct command
#      to run themselves to enable the native RDP service, which is the only
#      reliable method.
# ==================================================================================

set -e
if [[ $EUID -ne 0 ]]; then
   echo "This script must be run as root. Please use 'sudo ./02-configure-software.sh'"
   exit 1
fi

REAL_USER="${SUDO_USER:-$(logname)}"
USER_HOME=$(getent passwd "$REAL_USER" | cut -d: -f6)
LOG_FILE="${USER_HOME}/setup_log_02_software_$(date +%F_%H-%M-%S).log"
exec &> >(tee -a "$LOG_FILE")

echo "--- [SCRIPT 2/2] Software setup starting at $(date) ---"
echo "--- All output is being logged to: $LOG_FILE ---"
START_SECONDS=$(date +%s)

# --- SELF-CORRECTION STAGE ---
echo " "
echo ">>> [PRE-FLIGHT CHECK] Cleaning up any broken files from previous runs..."
rm -f /etc/apt/sources.list.d/nvidia-container-toolkit.list
rm -f /etc/apt/sources.list.d/docker.list
systemctl disable --now vncserver@1.service >/dev/null 2>&1 || true
rm -f /etc/systemd/system/vncserver@.service
apt-get remove --purge -y tigervnc-standalone-server >/dev/null 2>&1 || true
ufw delete allow 5901/tcp >/dev/null 2>&1 || true
echo "Cleanup complete."

# --- STAGE 1: CORE DEVELOPMENT & UTILITY TOOLS ---
echo " "
echo ">>> [1/4] Installing Essential Development & Utility Tools..."
apt-get update
apt-get install -y build-essential git python3-pip python3-venv cmake lm-sensors

# --- STAGE 2: ZSH + OH MY ZSH SHELL ENVIRONMENT ---
echo " "
echo ">>> [2/4] Setting up Zsh and Oh My Zsh..."
apt-get install -y zsh
if [ ! -d "${USER_HOME}/.oh-my-zsh" ]; then
    sudo -u "$REAL_USER" git clone https://github.com/ohmyzsh/ohmyzsh.git "${USER_HOME}/.oh-my-zsh"
    sudo -u "$REAL_USER" cp "${USER_HOME}/.oh-my-zsh/templates/zshrc.zsh-template" "${USER_HOME}/.zshrc"
fi
if [ "$(getent passwd $REAL_USER | cut -d: -f7)" != "$(which zsh)" ]; then
    chsh -s $(which zsh) $REAL_USER
fi

# --- STAGE 3: DOCKER AND NVIDIA CONTAINER TOOLKIT ---
echo " "
echo ">>> [3/4] Setting up Docker and NVIDIA Container Toolkit..."
apt-get install -y ca-certificates curl
install -m 0755 -d /etc/apt/keyrings
curl -fsSL "https://download.docker.com/linux/ubuntu/gpg" | gpg --dearmor -o /etc/apt/keyrings/docker.gpg
chmod a+r /etc/apt/keyrings/docker.gpg
echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null
curl -fsSL https://nvidia.github.io/libnvidia-container/gpgkey | gpg --dearmor -o /usr/share/keyrings/nvidia-container-toolkit-keyring.gpg
curl -s -L https://nvidia.github.io/libnvidia-container/stable/deb/nvidia-container-toolkit.list | sed 's#deb https://#deb [signed-by=/usr/share/keyrings/nvidia-container-toolkit-keyring.gpg] https://#g' | tee /etc/apt/sources.list.d/nvidia-container-toolkit.list
apt-get update
apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin nvidia-container-toolkit
usermod -aG docker $REAL_USER
nvidia-ctk runtime configure --runtime=docker
systemctl restart docker

# --- STAGE 4: CONFIGURE FIREWALL FOR RDP ---
echo " "
echo ">>> [4/4] Configuring Firewall (UFW) to allow RDP connections..."
ufw allow 3389/tcp
echo "Firewall rule added to allow incoming connections on port 3389."

# --- FINALIZATION ---
echo " "
echo "================================================================="
echo "    SCRIPT COMPLETE. SYSTEM PREPARATION IS FINISHED.    "
echo "================================================================="
echo "!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!"
echo "    >>> FINAL STEP: YOU MUST ENABLE RDP MANUALLY <<<"
echo "!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!"
echo "The script has installed all software and opened the firewall."
echo "To enable Remote Desktop, you must run the following command"
echo "AS YOUR NORMAL USER (danny), NOT with sudo:"
echo ""
echo "    systemctl --user enable --now gnome-remote-desktop.service"
echo ""
echo "After you run that one command, the setup will be complete."
echo "You can then connect from your Mac using the Microsoft Remote Desktop app."
echo "================================================================="

#12:14 9.14.25
