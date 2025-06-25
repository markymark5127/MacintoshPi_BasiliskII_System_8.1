#!/bin/bash
set -euo pipefail

MINECRAFT_MODE=false

if [[ $# -gt 0 && "$1" == "--with-minecraft" ]]; then
  MINECRAFT_MODE=true
  echo "🧱 Minecraft mode enabled — additional steps will be included."
fi

if [ "$EUID" -ne 0 ]; then
  echo "⚠️ Please run this script with sudo: sudo $0 [--with-minecraft]"
  exit 1
fi

TARGET_USER="${SUDO_USER:-$USER}"
USER_HOME=$(eval echo "~$TARGET_USER")

echo "🔧 Installing dependencies..."
sudo apt update
sudo apt install -y build-essential libsdl2-dev libsdl2-image-dev git hfsutils unclutter xbindkeys alsa-utils autoconf automake libtool libmpfr-dev feh

if $MINECRAFT_MODE; then
  echo "🧱 Installing Minecraft Pi Edition Reborn dependencies..."
  sudo apt install -y cmake g++ libsdl2-mixer-dev libsdl2-ttf-dev libcurl4-openssl-dev libglew-dev
  mkdir -p "$USER_HOME/mcpi-reborn"
  cd "$USER_HOME/mcpi-reborn"
  git clone https://github.com/TheBrokenRail/mcpi-reborn.git .
  ./scripts/install.sh
  cd -
fi

echo "📦 Cloning & building Basilisk II..."
if [ -d "macemu" ]; then
  echo "📁 'macemu' directory already exists. Skipping clone..."
else
  git clone https://github.com/kanjitalk755/macemu.git
fi
cd macemu/BasiliskII/src/Unix
./autogen.sh
make -j$(nproc)
if [ ! -f BasiliskII ]; then
  echo "❌ BasiliskII build failed. Aborting."
  exit 1
fi
sudo make install
cd ../../../../

echo "📁 Creating macos8 directory..."
mkdir -p "$USER_HOME/macos8" "$USER_HOME/macos8/Apps"

echo "📄 Checking and copying ROM and disk images..."
if [ ! -f LC575.ROM ]; then
  echo "❌ Missing LC575.ROM. Please place it in the script directory."
  exit 1
fi
cp LC575.ROM "$USER_HOME/macos8/"
cp DiskTools_MacOS8.image "$USER_HOME/macos8/"
cp Images/shutdown.png "$USER_HOME/macos8/shutdown.png"
cp Images/reboot.png "$USER_HOME/macos8/reboot.png"

echo "📦 Ensuring Mac OS 8.1 ISO is present and verified..."
ISO_PATH="$USER_HOME/macos8/MacOS8_1.iso"
echo "db5ec7aedcb4a3b8228c262cebcb44cf  $ISO_PATH" > "$USER_HOME/macos8/MacOS8_1.iso.md5"
if [ ! -f "$ISO_PATH" ] || ! md5sum -c "$USER_HOME/macos8/MacOS8_1.iso.md5"; then
  echo "📦 Reassembling Mac OS 8.1 ISO from parts..."
  cat MacOS8_1/MacOS8_1.iso.part_* > "$ISO_PATH"
  echo "🔍 Verifying checksum..."
  md5sum -c "$USER_HOME/macos8/MacOS8_1.iso.md5" || { echo "❌ ISO checksum failed. Aborting."; exit 1; }
fi

echo "💽 Creating dynamic macos8.img..."
TOTAL_MB=$(df --output=avail / | tail -1)
TOTAL_MB=$((TOTAL_MB / 1024))
RESERVED_MB=800
MAX_MB=30720  # 30 GB limit
IMG_MB=$((TOTAL_MB - RESERVED_MB))
if [ "$IMG_MB" -gt "$MAX_MB" ]; then
  IMG_MB=$MAX_MB
fi

echo "🧾 Requested disk image size: ${IMG_MB} MB"
echo "📂 Creating sparse disk image (instantly allocated, grows as needed)..."
truncate -s "${IMG_MB}M" "$USER_HOME/macos8/macos8.img"
ls -lh "$USER_HOME/macos8/macos8.img"

echo "📑 Copying Basilisk II install prefs..."
cp -f BasiliskII.install.prefs "$USER_HOME/.basilisk_ii_prefs"

echo "🎛️ Creating overlay scripts..."
cp shutdown_overlay.sh "$USER_HOME/shutdown_overlay.sh"
cp reboot_overlay.sh "$USER_HOME/reboot_overlay.sh"
chmod +x "$USER_HOME/shutdown_overlay.sh" "$USER_HOME/reboot_overlay.sh"

cat <<EOF > "$USER_HOME/.xbindkeysrc"
$USER_HOME/shutdown_overlay.sh
  Control+Alt + s

$USER_HOME/reboot_overlay.sh
  Control+Alt + r
EOF

echo "🖥️ Setting up GUI autostart for launch wrapper..."
if [ ! -f launch_wrapper.sh ]; then
  echo "❌ Error: launch_wrapper.sh not found in current directory!"
  exit 1
fi
cp launch_wrapper.sh "$USER_HOME/launch_wrapper.sh"
chmod +x "$USER_HOME/launch_wrapper.sh"

AUTOSTART_DIR="$USER_HOME/.config/lxsession/LXDE-pi"
mkdir -p "$AUTOSTART_DIR"
cat <<EOF > "$AUTOSTART_DIR/autostart"
@xset s off
@xset -dpms
@xset s noblank
@unclutter -idle 0
@xbindkeys
#@lxpanel
#@pcmanfm
@$USER_HOME/launch_wrapper.sh
EOF

# Lock Minecraft trigger if it exists
if [ -f "$USER_HOME/Downloads/.launch_minecraft" ]; then
  sudo chattr +i "$USER_HOME/Downloads/.launch_minecraft"
fi

# Fix file ownership if run via sudo
sudo chown -R "$TARGET_USER:$TARGET_USER" "$USER_HOME/macos8" "$USER_HOME"/.basilisk_ii_prefs "$USER_HOME"/launch_wrapper.sh "$USER_HOME"/shutdown_overlay.sh "$USER_HOME"/reboot_overlay.sh "$USER_HOME"/.xbindkeysrc

echo "👤 Enabling autologin to desktop..."
sudo raspi-config nonint do_boot_behaviour B4

echo "🔧 Configuring splash screen (optional)..."
sudo sed -i '/^disable_splash/d' /boot/config.txt
echo "disable_splash=1" | sudo tee -a /boot/config.txt
if [ -f Images/apple_splash.png ]; then
  sudo apt install -y plymouth plymouth-themes
  sudo cp Images/apple_splash.png /usr/share/plymouth/themes/pix/splash.png
fi

echo "🔐 Setting passwordless sudo for shutdown/reboot..."
if ! sudo grep -q '/sbin/shutdown' /etc/sudoers; then
  echo 'pi ALL=(ALL) NOPASSWD: /sbin/shutdown, /sbin/reboot' | sudo tee -a /etc/sudoers
fi

if [ -d InstallFiles ]; then
  read -p "🖥️ Press ENTER after completing Mac OS 8.1 installation to finalize setup..." temp
  echo "📂 Copying InstallFiles into macos8.img → Applications folder..."
  MNT=$(mktemp -d)
  if ! sudo mount -o loop,uid="$TARGET_USER",gid="$TARGET_USER" -t hfsplus "$USER_HOME/macos8/macos8.img" "$MNT" 2>/dev/null; then
    echo "⚠️ hfsplus mount failed, attempting fallback to hfs..."
    if ! sudo mount -o loop,uid="$TARGET_USER",gid="$TARGET_USER" -t hfs "$USER_HOME/macos8/macos8.img" "$MNT"; then
      echo "❌ Failed to mount macos8.img. Make sure hfs/hfsplus support is installed."
      exit 1
    fi
  fi
  mkdir -p "$MNT/Applications"
  for item in InstallFiles/*; do
    name=$(basename "$item")
    [[ "$name" != "Minecraft" ]] && sudo cp -r "$item" "$MNT/Applications/"
  done
  if $MINECRAFT_MODE; then
    [[ -f InstallFiles/Minecraft/.launch_minecraft ]] && sudo cp InstallFiles/Minecraft/.launch_minecraft "$MNT/Applications/"
    [[ -d InstallFiles/Minecraft/Minecraft ]] && sudo cp -r InstallFiles/Minecraft/Minecraft "$MNT/Desktop/"
  fi
  sudo umount "$MNT"
  rmdir "$MNT"
else
  echo "⚠️ No InstallFiles directory found. Skipping app injection step."
fi

cp -f BasiliskII.final.prefs "$USER_HOME/.basilisk_ii_prefs"

echo "✅ Setup complete. Rebooting..."
sleep 5
sudo reboot
