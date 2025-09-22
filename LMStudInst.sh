#!/bin/bash

# --- Configuration ---
# This script assumes the AppImage is in the user's Downloads folder.
DOWNLOADS_DIR="$HOME/Downloads"
# The target directory for the application binary.
APP_DIR="$HOME/Applications"
# The standard directory for user-specific desktop launcher files.
LAUNCHER_DIR="$HOME/.local/share/applications"
# The standard directory for user-specific icons.
ICON_DIR="$HOME/.local/share/icons"
ICON_URL="https://lmstudio.ai/assets/icon-256.png"
ICON_NAME="lmstudio.png"

# --- Script Start ---
echo "Starting LMStudio installation script..."

# 1. Find the LMStudio AppImage in the Downloads directory.
# The `find` command is robust and handles spaces or special characters.
APPIMAGE_SOURCE_PATH=$(find "$DOWNLOADS_DIR" -name "LM-Studio-*.AppImage" -print -quit)

if [ -z "$APPIMAGE_SOURCE_PATH" ]; then
    echo "Error: LM-Studio AppImage not found in $DOWNLOADS_DIR."
    echo "Please download it from https://lmstudio.ai/ and try again."
    exit 1
fi

APPIMAGE_BASENAME=$(basename "$APPIMAGE_SOURCE_PATH")
echo "Found AppImage: $APPIMAGE_BASENAME"

# 2. Create the target directories if they don't exist.
echo "Ensuring directories exist..."
mkdir -p "$APP_DIR"
mkdir -p "$LAUNCHER_DIR"
mkdir -p "$ICON_DIR"

# 3. Move the AppImage to the Applications folder.
APPIMAGE_DEST_PATH="$APP_DIR/$APPIMAGE_BASENAME"
echo "Moving AppImage to $APPIMAGE_DEST_PATH..."
mv "$APPIMAGE_SOURCE_PATH" "$APPIMAGE_DEST_PATH"

# 4. Make the AppImage executable.
echo "Setting executable permissions for the AppImage..."
chmod +x "$APPIMAGE_DEST_PATH"

# 5. Download the application icon.
ICON_DEST_PATH="$ICON_DIR/$ICON_NAME"
echo "Downloading application icon to $ICON_DEST_PATH..."
# Use curl to download the icon file. The -sL options make it silent and follow redirects.
curl -sL "$ICON_URL" -o "$ICON_DEST_PATH"

# 6. Create the desktop launcher shortcut.
LAUNCHER_FILE_PATH="$LAUNCHER_DIR/lmstudio.desktop"
echo "Creating desktop launcher at $LAUNCHER_FILE_PATH..."

# Use a "here document" (cat <<EOL) to write the .desktop file content.
# Using full, quoted paths is crucial for the Exec and Icon lines.
cat > "$LAUNCHER_FILE_PATH" <<EOL
[Desktop Entry]
Version=1.0
Type=Application
Name=LMStudio
Comment=Discover, download, and run local LLMs
Exec="$APPIMAGE_DEST_PATH" %U
Icon=$ICON_DEST_PATH
Categories=Development;Utility;
Terminal=false
EOL

# 7. Update the desktop database.
# This is the crucial step to make the shortcut immediately visible and working.
echo "Updating the application database..."
if command -v update-desktop-database &> /dev/null; then
    update-desktop-database "$LAUNCHER_DIR"
else
    echo "Warning: 'update-desktop-database' command not found. You may need to log out and log back in for the shortcut to appear."
fi

echo "--------------------------------------------------"
echo "✅ Installation complete!"
echo "LMStudio should now be available in your application menu."
echo ""
echo "Reminder: LMStudio requires 'libfuse2' to run. If it doesn't start, open a terminal and run:"
echo "sudo apt update && sudo apt install libfuse2"
echo "--------------------------------------------------"

exit 0
