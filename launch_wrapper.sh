#!/bin/bash
set -e

echo "🧠 Launching Mac OS 8.1 in fullscreen kiosk mode..."

# Hide the mouse cursor again just in case
unclutter -idle 0 &

# Launch BasiliskII fullscreen
BasiliskII

# If BasiliskII exits, show message and reboot after short delay
echo "❌ BasiliskII exited. Rebooting in 10 seconds..."
sleep 10
sudo reboot
