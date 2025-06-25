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

# Determine the non-root user running this script so we can place files in the
# correct home directory when executed via sudo.
TARGET_USER="${SUDO_USER:-$USER}"
USER_HOME=$(eval echo "~$TARGET_USER")

echo "🔧 Installing dependencies..."
sudo apt update
sudo apt install -y build-essential libsdl2-dev libsdl2-image-dev git hfsutils xinit x11-xserver-utils unclutter feh xbindkeys alsa-utils autoconf automake libtool libmpfr-dev

if $MINECRAFT_MODE; then
  echo "🧱 Installing Minecraft Pi Edition Reborn dependencies..."
  sudo apt install -y cmake g++ libsdl2-dev libsdl2-image-dev libsdl2-mixer-dev \
    libsdl2-ttf-dev libcurl4-openssl-dev libglew-dev
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
sudo make install
cd ../../../../

echo "📁 Creating macos8 directory..."
mkdir -p "$USER_HOME/macos8" "$USER_HOME/macos8/Apps"

echo "📄 Copying ROM and disk images..."
cp LC575.ROM "$USER_HOME/macos8/"
cp DiskTools_MacOS8.image "$USER_HOME/macos8/"
cp shutdown.png "$USER_HOME/macos8/"
cp reboot.png "$USER_HOME/macos8/"

# Reassemble Mac OS 8.1 ISO from parts if not already present
if [ ! -f "$USER_HOME/macos8/MacOS8_1.iso" ]; then
  echo "📦 Reassembling Mac OS 8.1 ISO from parts..."
  cat MacOS8_1/MacOS8_1.iso.part_* > "$USER_HOME/macos8/MacOS8_1.iso"
  echo "🔍 Verifying checksum..."
  echo "db5ec7aedcb4a3b8228c262cebcb44cf  $USER_HOME/macos8/MacOS8_1.iso" > "$USER_HOME/macos8/MacOS8_1.iso.md5"
  if md5sum -c "$USER_HOME/macos8/MacOS8_1.iso.md5"; then
    echo "✅ ISO checksum verified."
  else
    echo "❌ Checksum mismatch! Aborting setup."
    exit 1
  fi
fi

echo "💽 Creating dynamic macos8.img..."
TOTAL_MB=$(df --output=avail / | tail -1)
TOTAL_MB=$((TOTAL_MB / 1024))
RESERVED_MB=500

if $MINECRAFT_MODE; then
  RESERVED_MB=800  # reserve more space if Minecraft is used
fi

IMG_MB=$((TOTAL_MB - RESERVED_MB))
dd if=/dev/zero of="$USER_HOME/macos8/macos8.img" bs=1M count=$IMG_MB
mkfs.hfs "$USER_HOME/macos8/macos8.img"

if [ -d InstallFiles ]; then
  echo "📂 Copying InstallFiles into macos8.img → Applications folder..."
  command -v hmount >/dev/null 2>&1 || { echo "❌ hfsutils not found in PATH. Aborting."; exit 1; }

  hmount "$USER_HOME/macos8/macos8.img"

  if ! hls ":Applications" > /dev/null 2>&1; then
    echo "📁 Applications folder not found. Creating it..."
    hmkdir ":Applications"
  fi

  echo "📄 Copying general apps to :Applications..."
  for item in InstallFiles/*; do
    name=$(basename "$item")
    if [[ "$name" != "Minecraft" ]]; then
      hcopy -r "$item" ":Applications:"
    fi
  done

  if $MINECRAFT_MODE; then
    echo "🧱 Minecraft mode — copying Minecraft launcher files..."
    if [ -f InstallFiles/Minecraft/.launch_minecraft ]; then
      hcopy InstallFiles/Minecraft/.launch_minecraft ":Applications:"
    fi
    if [ -d InstallFiles/Minecraft/Minecraft ]; then
      hcopy -r InstallFiles/Minecraft/Minecraft ":Desktop:"
    fi
  fi

  humount
fi


echo "📑 Copying Basilisk II install prefs..."
cp BasiliskII.install.prefs "$USER_HOME/.basilisk_ii_prefs"

echo "🎛️ Creating overlay scripts..."
cp shutdown_overlay.sh "$USER_HOME/shutdown_overlay.sh"
cp reboot_overlay.sh "$USER_HOME/reboot_overlay.sh"
chmod +x "$USER_HOME/shutdown_overlay.sh" "$USER_HOME/reboot_overlay.sh"

echo "🧠 Setting up xbindkeys hotkeys..."
cat <<EOF > "$USER_HOME/.xbindkeysrc"
$USER_HOME/shutdown_overlay.sh
  Control+Alt + s

$USER_HOME/reboot_overlay.sh
  Control+Alt + r
EOF

echo "🖥️ Setting up X autostart..."
if $MINECRAFT_MODE; then
  echo "➡️ Using Minecraft-aware launch wrapper..."
  cp launch_wrapper.sh "$USER_HOME/launch_wrapper.sh"
  chmod +x "$USER_HOME/launch_wrapper.sh"

  cat <<EOF > "$USER_HOME/.xinitrc"
#!/bin/bash
xset s off
xset -dpms
xset s noblank
unclutter -idle 0 &
xbindkeys &
\$USER_HOME/launch_wrapper.sh
EOF
else
  echo "➡️ Using standard BasiliskII launch..."
  cat <<EOF > "$USER_HOME/.xinitrc"
#!/bin/bash
xset s off
xset -dpms
xset s noblank
unclutter -idle 0 &
xbindkeys &
BasiliskII
EOF
fi

chmod +x "$USER_HOME/.xinitrc"

echo "👤 Enabling autologin to console..."
if ! sudo raspi-config nonint do_boot_behaviour B2; then
  echo "⚠️ Autologin setup failed. You may need to enable it manually via raspi-config."
fi

if ! grep -Fxq "startx" "$USER_HOME/.bash_profile"; then
  echo "startx" >> "$USER_HOME/.bash_profile"
fi

echo "🔐 Setting passwordless sudo for shutdown/reboot..."
if ! sudo grep -q '/sbin/shutdown' /etc/sudoers; then
  echo 'pi ALL=(ALL) NOPASSWD: /sbin/shutdown, /sbin/reboot' | sudo tee -a /etc/sudoers
fi

# Post-install cleanup prompt
read -p "🖥️ Press ENTER after completing Mac OS 8.1 installation to finalize setup..." temp
cp BasiliskII.final.prefs "$USER_HOME/.basilisk_ii_prefs"

echo "✅ Installation media removed from prefs. Ready to boot into Mac OS 8.1."

echo "✅ Setup complete. Rebooting..."
sleep 5
sudo reboot
