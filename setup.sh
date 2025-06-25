#!/bin/bash
set -e

MINECRAFT_MODE=false

if [[ "$1" == "--with-minecraft" ]]; then
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
git clone https://github.com/kanjitalk755/macemu.git
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

echo "📄 Copying ROM and disk images..."
cp LC575.ROM "$USER_HOME/macos8/"
cp DiskTools_MacOS8.image "$USER_HOME/macos8/"
cp shutdown.png "$USER_HOME/macos8/"
cp reboot.png "$USER_HOME/macos8/"

if [ ! -f "$USER_HOME/macos8/MacOS8_1.iso" ]; then
  echo "📦 Reassembling Mac OS 8.1 ISO from parts..."
  cat MacOS8_1/MacOS8_1.iso.part_* > "$USER_HOME/macos8/MacOS8_1.iso"
  echo "🔍 Verifying checksum..."
  echo "db5ec7aedcb4a3b8228c262cebcb44cf  $USER_HOME/macos8/MacOS8_1.iso" > "$USER_HOME/macos8/MacOS8_1.iso.md5"
  md5sum -c "$USER_HOME/macos8/MacOS8_1.iso.md5"
fi

echo "💽 Creating dynamic macos8.img..."
TOTAL_MB=$(df --output=avail / | tail -1)
TOTAL_MB=$((TOTAL_MB / 1024))
RESERVED_MB=800
IMG_MB=$((TOTAL_MB - RESERVED_MB))
dd if=/dev/zero of="$USER_HOME/macos8/macos8.img" bs=1M count=$IMG_MB
mkfs.hfs "$USER_HOME/macos8/macos8.img"

if [ -d InstallFiles ]; then
  echo "📂 Copying InstallFiles into macos8.img → Applications folder..."
  hmount "$USER_HOME/macos8/macos8.img"
  if ! hls ":Applications" > /dev/null 2>&1; then hmkdir ":Applications"; fi
  for item in InstallFiles/*; do
    name=$(basename "$item")
    [[ "$name" != "Minecraft" ]] && hcopy -r "$item" ":Applications:"
  done
  if $MINECRAFT_MODE; then
    [[ -f InstallFiles/Minecraft/.launch_minecraft ]] && hcopy InstallFiles/Minecraft/.launch_minecraft ":Applications/"
    [[ -d InstallFiles/Minecraft/Minecraft ]] && hcopy -r InstallFiles/Minecraft/Minecraft ":Desktop:"
  fi
  humount
fi

echo "📑 Copying Basilisk II install prefs..."
cp BasiliskII.install.prefs "$USER_HOME/.basilisk_ii_prefs"

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

chmod +x "$USER_HOME/launch_wrapper.sh"

    if [ -f "$USER_HOME/Downloads/.launch_minecraft" ]; then
      sudo chattr +i "$USER_HOME/Downloads/.launch_minecraft"
    fi


echo "👤 Enabling autologin to desktop..."
sudo raspi-config nonint do_boot_behaviour B4

echo "🔧 Configuring splash screen (optional)..."
sudo sed -i '/^disable_splash/d' /boot/config.txt
echo "disable_splash=1" | sudo tee -a /boot/config.txt
if [ -f apple_splash.png ]; then
  sudo apt install -y plymouth plymouth-themes
  sudo cp apple_splash.png /usr/share/plymouth/themes/pix/splash.png
fi

echo "🔐 Setting passwordless sudo for shutdown/reboot..."
if ! sudo grep -q '/sbin/shutdown' /etc/sudoers; then
  echo 'pi ALL=(ALL) NOPASSWD: /sbin/shutdown, /sbin/reboot' | sudo tee -a /etc/sudoers
fi

read -p "🖥️ Press ENTER after completing Mac OS 8.1 installation to finalize setup..." temp
cp BasiliskII.final.prefs "$USER_HOME/.basilisk_ii_prefs"

echo "✅ Setup complete. Rebooting..."
sleep 5
sudo reboot
