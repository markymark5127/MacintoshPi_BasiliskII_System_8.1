#!/bin/bash
set -e

echo "🔧 Installing dependencies..."
sudo apt update
sudo apt install -y build-essential libsdl2-dev libsdl2-image-dev git hfsutils xinit x11-xserver-utils unclutter feh xbindkeys alsa-utils

echo "📦 Cloning & building Basilisk II..."
git clone https://github.com/cebix/macemu.git
cd macemu/BasiliskII/src/Unix
./autogen.sh
make -j$(nproc)
sudo make install
cd ../../../../

echo "📁 Creating macos8 directory..."
mkdir -p ~/macos8 ~/macos8/Apps

echo "📄 Copying ROM and disk images..."
cp LC575.ROM ~/macos8/
cp DiskTools_MacOS8.image ~/macos8/
cp shutdown.png ~/macos8/
cp reboot.png ~/macos8/

# Reassemble Mac OS 8.1 ISO from parts if not already present
if [ ! -f ~/macos8/MacOS8_1.iso ]; then
  echo "📦 Reassembling Mac OS 8.1 ISO from parts..."
  cat MacOS8_1.iso.part_* > ~/macos8/MacOS8_1.iso

  echo "🔍 Verifying checksum..."
  echo "db5ec7aedcb4a3b8228c262cebcb44cf  ~/macos8/MacOS8_1.iso" > ~/macos8/MacOS8_1.iso.md5
  if md5sum -c ~/macos8/MacOS8_1.iso.md5; then
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
dd if=/dev/zero of=~/macos8/macos8.img bs=1M count=$IMG_MB
mkfs.hfs ~/macos8/macos8.img

if [ -d InstallFiles ]; then
  echo "📂 Copying InstallFiles into macos8.img..."
  hmount ~/macos8/macos8.img
  for file in InstallFiles/*; do
    hcopy "$file" ":"
  done
  humount
fi

echo "📑 Copying Basilisk II prefs..."
cp BasiliskII.prefs ~/.basilisk_ii_prefs

echo "🎛️ Creating overlay scripts..."
cp shutdown_overlay.sh ~/shutdown_overlay.sh
cp reboot_overlay.sh ~/reboot_overlay.sh
chmod +x ~/shutdown_overlay.sh ~/reboot_overlay.sh

echo "🧠 Setting up xbindkeys hotkeys..."
cat <<EOF > ~/.xbindkeysrc
"/home/pi/shutdown_overlay.sh"
  Control+Alt + s

"/home/pi/reboot_overlay.sh"
  Control+Alt + r
EOF

echo "🖥️ Setting up X autostart..."
cat <<EOF > ~/.xinitrc
#!/bin/bash
xset s off
xset -dpms
xset s noblank
unclutter -idle 0 &
xbindkeys &
BasiliskII
EOF
chmod +x ~/.xinitrc

echo "👤 Enabling autologin to console..."
sudo raspi-config nonint do_boot_behaviour B2
echo "startx" >> ~/.bash_profile

echo "🔐 Setting passwordless sudo for shutdown/reboot..."
echo 'pi ALL=(ALL) NOPASSWD: /sbin/shutdown, /sbin/reboot' | sudo tee -a /etc/sudoers

echo "✅ Setup complete. Rebooting..."
sleep 5
sudo reboot
