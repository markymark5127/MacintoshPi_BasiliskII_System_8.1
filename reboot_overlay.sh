#!/bin/bash
feh --fullscreen ~/macos8/reboot.png &
FEH_PID=$!
sleep 3
kill $FEH_PID
sudo reboot
