#!/bin/bash
set -euo pipefail
feh --fullscreen "$HOME/macos8/reboot.png" &
FEH_PID=$!
trap "kill $FEH_PID 2>/dev/null || true" EXIT
sleep 3
kill "$FEH_PID"
sudo reboot

