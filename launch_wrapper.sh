#!/bin/bash

# Wrapper to toggle between BasiliskII and Minecraft Pi Edition Reborn
TRIGGER_FILE="$HOME/Downloads/.launch_minecraft"
MCPI_DIR="$HOME/mcpi-reborn"
MCPI_APPIMAGE=$(find "$MCPI_DIR" -name 'mcpi-reborn-*.AppImage' | head -n 1)

# Ensure shared directory exists
mkdir -p "$(dirname "$TRIGGER_FILE")"

echo "🌀 Starting kiosk loop (BasiliskII → Minecraft)..."

while true; do
  echo "🧠 Launching BasiliskII..."
  BasiliskII &
  EMU_PID=$!

  wait $EMU_PID
  echo "🧱 BasiliskII exited. Checking for Minecraft trigger..."

  if [ -f "$TRIGGER_FILE" ]; then
    echo "🧱 Trigger found — launching Minecraft Pi Edition Reborn..."
    rm "$TRIGGER_FILE"

    if [ -x "$MCPI_APPIMAGE" ]; then
      "$MCPI_APPIMAGE" &
    elif [ -x "$MCPI_DIR/mcpi-reborn-client" ]; then
      "$MCPI_DIR/mcpi-reborn-client" &
    else
      echo "❌ Minecraft executable not found. Skipping..."
      continue
    fi

    wait
    echo "🔁 Returning to BasiliskII..."
  else
    echo "❌ No trigger file. Exiting kiosk loop..."
    break
  fi
done
