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
PREFS_PATH="$USER_HOME/.basilisk_ii_prefs"

echo "🔧 Installing dependencies..."
sudo apt update
sudo apt install -y build-essential libsdl2-dev libsdl2-image-dev git hfsutils hfsprogs \
  unclutter xbindkeys alsa-utils autoconf automake libtool libmpfr-dev feh

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

cp LC575.ROM "$USER_HOME/macos8/LC575.ROM"
chmod 644 "$USER_HOME/macos8/LC575.ROM"
chown "$TARGET_USER:$TARGET_USER" "$USER_HOME/macos8/LC575.ROM"

cp DiskTools_MacOS8.image "$USER_HOME/macos8/DiskTools_MacOS8.image"
chmod 644 "$USER_HOME/macos8/DiskTools_MacOS8.image"
chown "$TARGET_USER:$TARGET_USER" "$USER_HOME/macos8/DiskTools_MacOS8.image"

cp Images/shutdown.png "$USER_HOME/macos8/shutdown.png"
chmod 644 "$USER_HOME/macos8/shutdown.png"
chown "$TARGET_USER:$TARGET_USER" "$USER_HOME/macos8/shutdown.png"

cp Images/reboot.png "$USER_HOME/macos8/reboot.png"
chmod 644 "$USER_HOME/macos8/reboot.png"
chown "$TARGET_USER:$TARGET_USER" "$USER_HOME/macos8/reboot.png"

echo "📦 Ensuring Mac OS 8.1 ISO is present and verified..."
ISO_PATH="$USER_HOME/macos8/MacOS8_1.iso"
echo "db5ec7aedcb4a3b8228c262cebcb44cf  $ISO_PATH" > "$USER_HOME/macos8/MacOS8_1.iso.md5"
if [ ! -f "$ISO_PATH" ] || ! md5sum -c "$USER_HOME/macos8/MacOS8_1.iso.md5"; then
  echo "📦 Reassembling Mac OS 8.1 ISO from parts..."
  cat MacOS8_1/MacOS8_1.iso.part_* > "$ISO_PATH"
  echo "🔍 Verifying checksum..."
  md5sum -c "$USER_HOME/macos8/MacOS8_1.iso.md5" || { echo "❌ ISO checksum failed. Aborting."; exit 1; }
fi
chmod 644 "$ISO_PATH"
chown "$TARGET_USER:$TARGET_USER" "$ISO_PATH"

echo "💽 Reconstructing macos8.img from parts..."

IMG_PARTS_DIR="Drive"
IMG_PATH="$USER_HOME/macos8/macos8.img"
MD5_EXPECTED="a2a8c2749940d42b7f0d11dc2aaabd2f"

if ls "$IMG_PARTS_DIR"/macos8.img.part_* 1> /dev/null 2>&1; then
  if [ -f "$IMG_PATH" ]; then
    echo "⚠️ Existing $IMG_PATH will be overwritten."
    rm -f "$IMG_PATH"
  fi

  echo "📦 Assembling image..."
  cat "$IMG_PARTS_DIR"/macos8.img.part_* > "$IMG_PATH"

  echo "🔍 Verifying checksum..."
  MD5_ACTUAL=$(md5sum "$IMG_PATH" | awk '{print $1}')
  if [ "$MD5_ACTUAL" != "$MD5_EXPECTED" ]; then
    echo "❌ Checksum mismatch! Expected $MD5_EXPECTED but got $MD5_ACTUAL"
    exit 1
  fi

  chmod 644 "$IMG_PATH"
  chown "$TARGET_USER:$TARGET_USER" "$IMG_PATH"
  echo "✅ macos8.img successfully assembled and verified."
else
  echo "❌ Image parts not found in $IMG_PARTS_DIR. Aborting."
  exit 1
fi

echo "📝 Creating install Basilisk II prefs file..."
if [ ! -f "$PREFS_PATH" ]; then
cat <<EOF > "$PREFS_PATH"
rom $USER_HOME/macos8/LC575.ROM
disk $USER_HOME/macos8/DiskTools_MacOS8.image
disk $USER_HOME/macos8/MacOS8_1.iso
disk $USER_HOME/macos8/macos8.img
extfs $USER_HOME/Downloads
screen win/800/600
seriala /dev/cu.BLTH
serialb /dev/null
ether slirp
udptunnel false
udpport 6066
bootdrive 0
bootdriver 0
ramsize 134217728
frameskip 2
modelid 14
cpu 4
fpu true
nocdrom false
nosound false
noclipconversion false
nogui true
jit false
jitfpu true
jitdebug false
jitcachesize 8192
jitlazyflush true
jitinline true
keyboardtype 5
keycodes false
mousewheelmode 0
mousewheellines 0
ignoresegv true
idlewait true
displaycolordepth 8
hotkey 0
scale_nearest false
scale_integer false
yearofs 0
dayofs 0
swap_opt_cmd false
sound_buffer 0
name_encoding 0
delay 0
init_grab false
EOF
  chown "$TARGET_USER:$TARGET_USER" "$PREFS_PATH"
  chmod 644 "$PREFS_PATH"
else
  echo "🧠 Prefs file already exists. Leaving it untouched."
fi

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

echo "🖥️ Configuring kiosk autologin..."
cp .xinitrc "$USER_HOME/.xinitrc"
cp launch_wrapper.sh "$USER_HOME/launch_wrapper.sh"
chmod +x "$USER_HOME/.xinitrc" "$USER_HOME/launch_wrapper.sh"
chown "$TARGET_USER:$TARGET_USER" "$USER_HOME/.xinitrc" "$USER_HOME/launch_wrapper.sh"
chown -R "$TARGET_USER:$TARGET_USER" "$USER_HOME/macos8" "$USER_HOME/.xbindkeysrc" \
  "$USER_HOME"/shutdown_overlay.sh "$USER_HOME"/reboot_overlay.sh

PROFILE_FILE="$USER_HOME/.bash_profile"
if ! grep -q 'exec startx' "$PROFILE_FILE" 2>/dev/null; then
  echo '[[ -z $DISPLAY && $XDG_VTNR -eq 1 ]] && exec startx' >> "$PROFILE_FILE"
  chown "$TARGET_USER:$TARGET_USER" "$PROFILE_FILE"
fi

touch "$USER_HOME/.hushlogin"
chown "$TARGET_USER:$TARGET_USER" "$USER_HOME/.hushlogin"

sudo raspi-config nonint do_boot_behaviour B2

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
  echo "🚀 Launching Basilisk II to begin installation..."
  sudo -u "$TARGET_USER" BasiliskII
  echo "📴 Basilisk II has closed."
  read -p "🕹️ Press Enter to continue setup..."
  
  echo "📝 Creating Basilisk II prefs file..."
  cat <<EOF > "$PREFS_PATH"
  rom $USER_HOME/macos8/LC575.ROM
  disk $USER_HOME/macos8/macos8.img
  extfs $USER_HOME/Downloads
  screen win/800/600
  seriala /dev/cu.BLTH
  serialb /dev/null
  ether slirp
  udptunnel false
  udpport 6066
  bootdrive 0
  bootdriver 0
  ramsize 134217728
  frameskip 2
  modelid 14
  cpu 4
  fpu true
  nocdrom false
  nosound false
  noclipconversion false
  nogui true
  jit false
  jitfpu true
  jitdebug false
  jitcachesize 8192
  jitlazyflush true
  jitinline true
  keyboardtype 5
  keycodes false
  mousewheelmode 0
  mousewheellines 0
  ignoresegv true
  idlewait true
  displaycolordepth 8
  hotkey 0
  scale_nearest false
  scale_integer false
  yearofs 0
  dayofs 0
  swap_opt_cmd false
  sound_buffer 0
  name_encoding 0
  delay 0
  init_grab false
EOF

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

echo "✅ Setup complete. Rebooting..."
sleep 5
sudo reboot
