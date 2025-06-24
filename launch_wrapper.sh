#  launch_wrapper.sh
#  Handles seamless switching between Basilisk II and Minecraft Pi Edition

# Shared folder inside the emulator maps to the Pi's Downloads directory
TRIGGER_FILE="$HOME/Downloads/.launch_minecraft"

# Ensure trigger file directory exists
mkdir -p "$(dirname "$TRIGGER_FILE")"

while true; do
  echo "🧠 Launching Basilisk II..."
  BasiliskII &
  EMULATOR_PID=$!

  # Wait until BasiliskII exits
  wait $EMULATOR_PID

  echo "🔍 Checking for Minecraft trigger..."
  if [ -f "$TRIGGER_FILE" ]; then
    echo "🧱 Launching Minecraft Pi Edition..."
    rm "$TRIGGER_FILE"

    # Launch Minecraft Pi Edition
    "$HOME/mcpi/minecraft-pi" &
    wait

    echo "🔁 Returning to Basilisk II..."
  else
    echo "❌ Basilisk II exited without Minecraft trigger. Exiting..."
    break
  fi
done
