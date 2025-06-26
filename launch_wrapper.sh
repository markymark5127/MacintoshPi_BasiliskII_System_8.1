#!/bin/bash
set -e

echo "🧠 Launching Mac OS 8.1 in fullscreen kiosk mode..."

# Hide the mouse cursor again just in case
unclutter -idle 0 &

# Launch BasiliskII fullscreen
BasiliskII

