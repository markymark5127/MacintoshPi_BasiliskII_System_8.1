#!/bin/bash

# Path to user’s home directory (ensure this is available if called via sudo)
TARGET_USER="${SUDO_USER:-$USER}"
USER_HOME=$(eval echo "~$TARGET_USER")

IMAGE_PATH="$USER_HOME/macos8/shutdown.png"

# Show the splash image fullscreen using feh
feh --fullscreen --auto-zoom --hide-pointer "$IMAGE_PATH" &

# Wait a moment so the image is visible
sleep 3

# Trigger shutdown
sudo shutdown -h now
