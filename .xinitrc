#!/bin/bash

# Resolve correct home directory
TARGET_USER="${SUDO_USER:-$USER}"
USER_HOME=$(eval echo "~$TARGET_USER")

# Disable screen blanking, power saving, and screen saver
xset s off
xset -dpms
xset s noblank

# Hide mouse cursor when idle
command -v unclutter >/dev/null && unclutter -idle 0 &

# Enable hotkey handling
command -v xbindkeys >/dev/null && xbindkeys &

# Run main app loop (e.g., BasiliskII → Minecraft)
exec "$USER_HOME/launch_wrapper.sh"
