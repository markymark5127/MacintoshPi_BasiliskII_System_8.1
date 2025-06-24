#  launch_wrapper.sh
#  Handles seamless switching between Basilisk II and Minecraft Pi Edition

TRIGGER_FILE="$HOME/Unix/.launch_minecraft"

# Ensure trigger file directory exists (in case user hasn't launched BasiliskII yet)
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
