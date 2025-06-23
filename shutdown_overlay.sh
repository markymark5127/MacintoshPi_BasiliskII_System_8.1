#!/bin/sh

#  shutdown_overlay.sh
#  
#
#  Created by Mark Mayne on 6/23/25.
#  
#!/bin/bash
feh --fullscreen ~/macos8/shutdown.png &
FEH_PID=$!
sleep 3
kill $FEH_PID
sudo shutdown now
