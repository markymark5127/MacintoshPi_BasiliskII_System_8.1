#!/bin/bash

# Disable screen blanking and power saving
xset s off
xset -dpms
xset s noblank

# Hide mouse cursor if available
command -v unclutter >/dev/null && unclutter -idle 0 &

# Launch BasiliskII fullscreen
BasiliskII

# After BasiliskII exits, check for reboot/shutdown triggers
if [ -f "$HOME/.reboot" ]; then
  echo "🔁 Reboot requested. Rebooting in 10 seconds..."
  sleep 10
  sudo reboot
elif [ -f "$HOME/.shutdown" ]; then
  echo "⏻ Shutdown requested. Shutting down in 10 seconds..."
  sleep 10
  sudo shutdown -h now
else
  echo "🛑 No trigger file found. Staying on terminal."
fi
