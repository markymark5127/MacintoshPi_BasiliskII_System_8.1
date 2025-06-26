#!/bin/bash
set -e

TARGET_USER="${SUDO_USER:-$USER}"
USER_HOME=$(eval echo "~$TARGET_USER")
IMAGE_PATH="$USER_HOME/macos8/shutdown.png"

# Verify splash image exists
if [ ! -f "$IMAGE_PATH" ]; then
  echo "❌ Shutdown image not found at $IMAGE_PATH"
  exit 1
fi

# Show shutdown splash
command -v feh >/dev/null && feh --fullscreen --auto-zoom --hide-pointer "$IMAGE_PATH" &

sleep 3

# Write shutdown trigger for .xinitrc to process
touch "$USER_HOME/.shutdown"
chown "$TARGET_USER:$TARGET_USER" "$USER_HOME/.shutdown"

# Kill BasiliskII (so .xinitrc can take over)
pkill -f BasiliskII || true

# Fallback: force shutdown
sudo shutdown -h now
