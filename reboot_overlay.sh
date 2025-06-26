#!/bin/bash

TARGET_USER="${SUDO_USER:-$USER}"
USER_HOME=$(eval echo "~$TARGET_USER")

IMAGE_PATH="$USER_HOME/macos8/reboot.png"

# Show splash
feh --fullscreen --auto-zoom --hide-pointer "$IMAGE_PATH" &

sleep 3

# Trigger reboot
sudo reboot
