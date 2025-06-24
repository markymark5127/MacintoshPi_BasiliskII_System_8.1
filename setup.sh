#!/bin/bash
set -e

if [ "$EUID" -ne 0 ]; then
  echo "⚠️ Please run this script with sudo: sudo $0"
  exit 1
fi

echo "🔧 Installing dependencies..."
sudo apt update
sudo apt install -y build-essential libsdl2-dev libsdl2-image-dev git hfsutils xinit x11-xserver-utils unclutter feh xbindkeys alsa-utils autoconf automake libtool

echo "📦 Cloning & building Basilisk II..."
git clone https://github.com/kanjitalk755/macemu.git
cd macemu/BasiliskII/src/Unix
./autogen.sh
make -j$(nproc)
sudo make install
cd ../../../../

echo "📁 Creating macos8 directory..."
mkdir -p "$HOME/macos8" "$HOME/macos8/Apps"

echo "📄 Copying ROM and disk images..."
cp LC575.ROM "$HOME/macos8/"
cp DiskTools_MacOS8.image "$HOME/macos8/"
cp shutdown.png "$HOME/macos8/"
cp reboot.png "$HOME/macos8/"

# Reassemble Mac OS 8.1 ISO from parts if not already present
if [ ! -f "$HOME/macos8/MacOS8_1.iso" ]; then
  echo "📦 Reassembling Mac OS 8.1 ISO from parts..."
  cat MacOS8_1/MacOS8_1.iso.part_* > "$HOME/macos8/MacOS8_1.iso"

  echo "🔍 Verifying checksum..."
  echo "db5ec7aedcb4a3b8228c262cebcb44cf  $HOME/macos8/MacOS8_1.iso" > "$HOME/macos8/MacOS8_1.iso.md5"
  if md5sum -c "$HOME/macos8/MacOS8_1.iso.md5"; then
    echo "✅ ISO checksum verified."
  else
    echo "❌ Checksum mismatch! Aborting setup."
    exit 1
  fi
fi

echo "💽 Creating dynamic macos8.img..."
TOTAL_MB=$(df --output=avail / | tail -1)
TOTAL_MB=$((TOTAL_MB / 1024))
IMG_MB=$((TOTAL_MB - 200))
dd if=/dev/zero of="$HOME/macos8/macos8.img" bs=1M count=$IMG_MB
mkfs.hfs "$HOME/macos8/macos8.img"

if [ -d InstallFiles ]; then
  echo "📂 Copying InstallFiles into macos8.img → Applications folder..."
  command -v hmount >/dev/null 2>&1 || { echo "❌ hfsutils not found in PATH. Aborting."; exit 1; }

  hmount "$HOME/macos8/macos8.img"
  if hls ":Applications" > /dev/null 2>&1; then
    echo "✅ Applications folder found on macos8.img."
  else
    echo "📁 Applications folder not found. Creating it..."
    hmkdir ":Applications"
  fi
  echo "📄 Recursively copying InstallFiles/* to :Applications:"
  hcopy -r InstallFiles/* ":Applications:"
  humount
fi

echo "📑 Copying Basilisk II install prefs..."
cp BasiliskII.install.prefs "$HOME/.basilisk_ii_prefs"

echo "🎛️ Creating overlay scripts..."
cp shutdown_overlay.sh "$HOME/shutdown_overlay.sh"
cp reboot_overlay.sh "$HOME/reboot_overlay.sh"
chmod +x "$HOME/shutdown_overlay.sh" "$HOME/reboot_overlay.sh"

echo "🧠 Setting up xbindkeys hotkeys..."
cat <<EOF > "$HOME/.xbindkeysrc"
/home/pi/shutdown_overlay.sh
  Control+Alt + s

/home/pi/reboot_overlay.sh
  Control+Alt + r
EOF

echo "🖥️ Setting up X autostart..."
cat <<EOF > "$HOME/.xinitrc"
#!/bin/bash
xset s off
xset -dpms
xset s noblank
unclutter -idle 0 &
xbindkeys &
BasiliskII
EOF
chmod +x "$HOME/.xinitrc"

echo "👤 Enabling autologin to console..."
if ! sudo raspi-config nonint do_boot_behaviour B2; then
  echo "⚠️ Autologin setup failed. You may need to enable it manually via raspi-config."
fi

if ! grep -Fxq "startx" "$HOME/.bash_profile"; then
  echo "startx" >> "$HOME/.bash_profile"
fi

echo "🔐 Setting passwordless sudo for shutdown/reboot..."
if ! sudo grep -q '/sbin/shutdown' /etc/sudoers; then
  echo 'pi ALL=(ALL) NOPASSWD: /sbin/shutdown, /sbin/reboot' | sudo tee -a /etc/sudoers
fi

# Post-install cleanup prompt
read -p "🖥️ Press ENTER after completing Mac OS 8.1 installation to finalize setup..." temp
cp BasiliskII.final.prefs "$HOME/.basilisk_ii_prefs"

echo "✅ Installation media removed from prefs. Ready to boot into Mac OS 8.1."

echo "✅ Setup complete. Rebooting..."
sleep 5
sudo reboot
