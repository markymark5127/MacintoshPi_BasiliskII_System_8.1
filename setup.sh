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

INSTALLER_DIR=$(dirname "$0")
TARGET_USER="${SUDO_USER:-$USER}"
USER_HOME=$(eval echo "~$TARGET_USER")
PREFS_PATH="$USER_HOME/.basilisk_ii_prefs"

set_ownership_and_perms() {
  local path="$1"
  local mode="$2"
  chown "$TARGET_USER:$TARGET_USER" "$path"
  chmod "$mode" "$path"
}

echo "🔧 Installing dependencies..."
sudo apt update
sudo apt install -y \
  build-essential libsdl2-dev libsdl2-image-dev git hfsutils hfsprogs \
  unclutter xbindkeys alsa-utils autoconf automake libtool libmpfr-dev feh \
  gobjc libudev-dev xa65 byacc texi2html flex libreadline-dev unzip \
  libxaw7-dev texinfo unar libgtk2.0-cil-dev libgtkglext1-dev libpulse-dev \
  bison libnet1 libnet1-dev libpcap0.8 libpcap0.8-dev libvte-dev \
  libasound2-dev raspberrypi-kernel-headers



if $MINECRAFT_MODE; then
  echo "🧱 Installing Minecraft Pi Edition Reborn dependencies..."
  sudo apt update
  sudo apt install flatpak -y
  flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo
  flatpak install flathub com.thebrokenrail.MCPIReborn
  if [ ! -f /Minecraft/libminecraftpe.so ]; then
    echo "❌ Missing libminecraftpe.so. Please place it in the script directory."
    exit 1
  fi
  cp /Minecraft/libminecraftpe.so "$USER_HOME/.minecraft-pi/overrides/libminecraftpe.so"
  set_ownership_and_perms "$USER_HOME/.minecraft-pi/overrides/libminecraftpe.so" 644
  if [ ! -f /Minecraft/Minecraft ]; then
    echo "❌ Missing Minecraft app. Please place it in the script directory."
    exit 1
  fi
  cp /Minecraft/Minecraft /InstallFiles/Minecraft
  set_ownership_and_perms /InstallFiles/Minecraft 644
  if [ ! -f /Minecraft/.launch_minecraft ]; then
    echo "❌ Missing Minecraft launch file. Please place it in the script directory."
    exit 1
  fi
  cp /Minecraft/.launch_minecraft /InstallFiles/.launch_minecraft
  set_ownership_and_perms /InstallFiles/.launch_minecraft 644

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

echo "📁 Creating macos8 folders..."
mkdir -p "$USER_HOME/macos8" "$USER_HOME/macos8/Apps" "$USER_HOME/macos8/DriveParts"
cp Drive/* "$USER_HOME/macos8/DriveParts"
set_ownership_and_perms "$USER_HOME/macos8/DriveParts" 755

echo "📝 Writing add_macos8_drive.sh helper script into macos8 folder..."

echo "📝 Writing add_macos8_drive.sh helper script into macos8 folder..."

cat <<'EOF' > "$USER_HOME/macos8/add_macos8_drive.sh"
#!/bin/bash
set -euo pipefail

echo "Enter a name for your new drive image (no spaces):"
read -r name

IMG_PARTS_DIR="\$HOME/macos8/DriveParts"
IMG_PATH="\$HOME/macos8/\${name}.img"
MD5_EXPECTED="a2a8c2749940d42b7f0d11dc2aaabd2f"
PREFS_FILE="\$HOME/.basilisk_ii_prefs"

if ls "\$IMG_PARTS_DIR"/macos8.img.part_* 1> /dev/null 2>&1; then
  if [ -f "\$IMG_PATH" ]; then
    echo "⚠️ Existing \$IMG_PATH will be overwritten."
    rm -f "\$IMG_PATH"
  fi

  echo "📦 Assembling image..."
  cat "\$IMG_PARTS_DIR"/macos8.img.part_* > "\$IMG_PATH"

  echo "🔍 Verifying checksum..."
  MD5_ACTUAL=\$(md5sum "\$IMG_PATH" | awk '{print \$1}')
  if [ "\$MD5_ACTUAL" != "\$MD5_EXPECTED" ]; then
    echo "❌ Checksum mismatch! Expected \$MD5_EXPECTED but got \$MD5_ACTUAL"
    exit 1
  fi

  chmod 644 "\$IMG_PATH"
  echo "✅ \$IMG_PATH successfully assembled and verified."

  echo "➕ Adding new disk line to BasiliskII prefs..."
  echo "disk \$IMG_PATH" >> "\$PREFS_FILE"
  echo "✅ Added: disk \$IMG_PATH"

else
  echo "❌ Image parts not found in \$IMG_PARTS_DIR. Aborting."
  exit 1
fi
EOF

chown "$TARGET_USER:$TARGET_USER" "$USER_HOME/macos8/add_macos8_drive.sh"
chmod +x "$USER_HOME/macos8/add_macos8_drive.sh"

echo "✅ add_macos8_drive.sh created in $USER_HOME/macos8"


chown "$TARGET_USER:$TARGET_USER" "$USER_HOME/macos8/add_macos8_drive.sh"
chmod +x "$USER_HOME/macos8/add_macos8_drive.sh"

echo "✅ add_macos8_drive.sh created in $USER_HOME/macos8"


echo "📄 Checking and copying ROM and disk images..."
if [ ! -f LC575.ROM ]; then
  echo "❌ Missing LC575.ROM. Please place it in the script directory."
  exit 1
fi

cp LC575.ROM "$USER_HOME/macos8/LC575.ROM"
set_ownership_and_perms "$USER_HOME/macos8/LC575.ROM" 644

cp DiskTools_MacOS8.image "$USER_HOME/macos8/DiskTools_MacOS8.image"
set_ownership_and_perms "$USER_HOME/macos8/DiskTools_MacOS8.image" 644

cp Images/shutdown.png "$USER_HOME/macos8/shutdown.png"
set_ownership_and_perms "$USER_HOME/macos8/shutdown.png" 644

cp Images/reboot.png "$USER_HOME/macos8/reboot.png"
set_ownership_and_perms "$USER_HOME/macos8/reboot.png" 644

echo "📦 Ensuring Mac OS 8.1 ISO is present and verified..."
ISO_PATH="$USER_HOME/macos8/MacOS8_1.iso"
echo "db5ec7aedcb4a3b8228c262cebcb44cf  $ISO_PATH" > "$USER_HOME/macos8/MacOS8_1.iso.md5"
if [ ! -f "$ISO_PATH" ] || ! md5sum -c "$USER_HOME/macos8/MacOS8_1.iso.md5"; then
  echo "📦 Reassembling Mac OS 8.1 ISO from parts..."
  cat MacOS8_1/MacOS8_1.iso.part_* > "$ISO_PATH"
  echo "🔍 Verifying checksum..."
  md5sum -c "$USER_HOME/macos8/MacOS8_1.iso.md5" || { echo "❌ ISO checksum failed. Aborting."; exit 1; }
fi
set_ownership_and_perms "$ISO_PATH" 644

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

  set_ownership_and_perms "$IMG_PATH" 644
  echo "✅ macos8.img successfully assembled and verified."
else
  echo "❌ Image parts not found in $IMG_PARTS_DIR. Aborting."
  exit 1
fi

echo "📝 Writing Basilisk II Install prefs file..."
if [ -f "$PREFS_PATH" ]; then
  i=1
  while [ -f "$PREFS_PATH.bak.$i" ]; do
    i=$((i + 1))
  done
  cp "$PREFS_PATH" "$PREFS_PATH.bak.$i"
  echo "🔐 Backup created: $PREFS_PATH.bak.$i"
fi

: > "$PREFS_PATH"

cat <<EOF > "$PREFS_PATH"
rom $USER_HOME/macos8/LC575.ROM
disk $USER_HOME/macos8/DiskTools_MacOS8.image
disk $USER_HOME/macos8/MacOS8_1.iso
disk $USER_HOME/macos8/macos8.img
extfs $USER_HOME/Downloads
screen dga/800/600
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

set_ownership_and_perms "$PREFS_PATH" 644

echo "🧩 Installing kiosk files..."

# Write launch wrapper
cat <<'EOF' > "$USER_HOME/launch_wrapper.sh"
#!/bin/bash
set -euo pipefail

echo "🌀 Starting BasiliskII ↔ Minecraft kiosk supervisor"

TARGET_USER="${SUDO_USER:-$USER}"
USER_HOME=$(eval echo "~$TARGET_USER")

BASILISKII_CMD="BasiliskII --config \"$USER_HOME/.basilisk_ii_prefs\""
MINECRAFT_CMD="flatpak run com.thebrokenrail.MCPIReborn"

# Paths for triggers
MINECRAFT_TRIGGER="$USER_HOME/Downloads/.launch_minecraft"
REBOOT_TRIGGER="$USER_HOME/.reboot"
SHUTDOWN_TRIGGER="$USER_HOME/.shutdown"

while true; do
  echo "🚀 Launching BasiliskII..."
  eval $BASILISKII_CMD

  echo "🛑 BasiliskII has exited."

  # Check for reboot or shutdown triggers
  if [ -f "$REBOOT_TRIGGER" ]; then
    echo "🔁 Reboot trigger detected!"
    rm -f "$REBOOT_TRIGGER"
    sudo reboot
    exit 0
  fi

  if [ -f "$SHUTDOWN_TRIGGER" ]; then
    echo "⏻ Shutdown trigger detected!"
    rm -f "$SHUTDOWN_TRIGGER"
    sudo shutdown -h now
    exit 0
  fi

  # Check for Minecraft trigger
  if [ -f "$MINECRAFT_TRIGGER" ]; then
    echo "🎮 Minecraft launch trigger detected!"
    rm -f "$MINECRAFT_TRIGGER"

    echo "✅ Starting Minecraft Pi Edition Reborn..."
    eval $MINECRAFT_CMD

    echo "🎮 Minecraft has exited. Returning to BasiliskII."
    # Loop continues → BasiliskII relaunches
  else
    echo "⏳ No immediate triggers found. Waiting 5 seconds to see if reboot is desired..."
    sleep 5

    # Re-check reboot/shutdown triggers after wait
    if [ -f "$REBOOT_TRIGGER" ]; then
      echo "🔁 Reboot trigger detected (after delay)!"
      rm -f "$REBOOT_TRIGGER"
      sudo reboot
      exit 0
    fi

    if [ -f "$SHUTDOWN_TRIGGER" ]; then
      echo "⏻ Shutdown trigger detected (after delay)!"
      rm -f "$SHUTDOWN_TRIGGER"
      sudo shutdown -h now
      exit 0
    fi

    if [ -f "$MINECRAFT_TRIGGER" ]; then
      echo "🎮 Minecraft launch trigger detected (after delay)!"
      rm -f "$MINECRAFT_TRIGGER"
      echo "✅ Starting Minecraft Pi Edition Reborn..."
      eval $MINECRAFT_CMD
      echo "🎮 Minecraft has exited. Returning to BasiliskII."
      continue
    fi

    # Nothing else triggered → treat as shutdown request
    echo "⚠️ No triggers after delay. Assuming guest chose shutdown. Shutting down host."
    sudo shutdown -h now
    exit 0
  fi
done

EOF

# Write new .xinitrc
cat <<'EOF' > "$USER_HOME/.xinitrc"
#!/bin/bash

export DISPLAY=:0

# Disable screen blanking and power saving
xset s off
xset -dpms
xset s noblank

# Hide mouse cursor if available
command -v unclutter >/dev/null && unclutter -idle 0 &

# Launch BasiliskII fullscreen
BasiliskII

# After BasiliskII exits, check for reboot/shutdown triggers
if [ -f "$HOME/.reboot" ]; then
  echo "🔁 Reboot requested. Rebooting in 10 seconds..."
  sleep 10
  sudo reboot
elif [ -f "$HOME/.shutdown" ]; then
  echo "⏻ Shutdown requested. Shutting down in 10 seconds..."
  sleep 10
  sudo shutdown -h now
else
  echo "🛑 No trigger file found. Staying on terminal."
fi
EOF

# Write .xbindkeysrc
cat <<'EOF' > "$USER_HOME/.xbindkeysrc"
# Shutdown: Ctrl + Alt + S
$HOME/shutdown_overlay.sh
  Control+Alt + s

# Reboot: Ctrl + Alt + R
$HOME/reboot_overlay.sh
  Control+Alt + r
EOF

# Write shutdown_overlay.sh
cat <<'EOF' > "$USER_HOME/shutdown_overlay.sh"
#!/bin/bash
set -e

TARGET_USER="${SUDO_USER:-$USER}"
USER_HOME=$(eval echo "~$TARGET_USER")
IMAGE_PATH="$USER_HOME/macos8/shutdown.png"

# Verify splash image exists
if [ ! -f "$IMAGE_PATH" ]; then
  echo "❌ Shutdown image not found at $IMAGE_PATH"
  exit 1
fi

# Show shutdown splash
command -v feh >/dev/null && feh --fullscreen --auto-zoom --hide-pointer "$IMAGE_PATH" &

sleep 3

# Write shutdown trigger for .xinitrc to process
touch "$USER_HOME/.shutdown"
chown "$TARGET_USER:$TARGET_USER" "$USER_HOME/.shutdown"

# Kill BasiliskII (so .xinitrc can take over)
pkill -f BasiliskII || true

# Fallback: force shutdown
sudo shutdown -h now
EOF

# Write reboot_overlay.sh
cat <<'EOF' > "$USER_HOME/reboot_overlay.sh"
#!/bin/bash
set -e

TARGET_USER="${SUDO_USER:-$USER}"
USER_HOME=$(eval echo "~$TARGET_USER")
IMAGE_PATH="$USER_HOME/macos8/reboot.png"

# Verify splash image exists
if [ ! -f "$IMAGE_PATH" ]; then
  echo "❌ Reboot image not found at $IMAGE_PATH"
  exit 1
fi

# Show reboot splash
command -v feh >/dev/null && feh --fullscreen --auto-zoom --hide-pointer "$IMAGE_PATH" &

sleep 3

# Write reboot trigger for .xinitrc to process
touch "$USER_HOME/.reboot"
chown "$TARGET_USER:$TARGET_USER" "$USER_HOME/.reboot"

# Kill BasiliskII (so .xinitrc can take over)
pkill -f BasiliskII || true

# Fallback: force reboot
sudo reboot
EOF

# Set ownership and permissions
chown "$TARGET_USER:$TARGET_USER" "$USER_HOME/.xinitrc" "$USER_HOME/.xbindkeysrc"
chmod 644 "$USER_HOME/.xinitrc" "$USER_HOME/.xbindkeysrc"

chmod +x "$USER_HOME/shutdown_overlay.sh" "$USER_HOME/reboot_overlay.sh"
chown "$TARGET_USER:$TARGET_USER" "$USER_HOME/shutdown_overlay.sh" "$USER_HOME/reboot_overlay.sh"


echo "📝 Writing $USER_HOME/.bash_profile for console autostart..."
cat <<'EOF' > "$USER_HOME/.bash_profile"
if [ -z "$DISPLAY" ] && [ "$XDG_VTNR" -eq 1 ]; then
  "$HOME/launch_wrapper.sh" >> "$HOME/kiosk.log" 2>&1
fi
EOF
chown "$TARGET_USER:$TARGET_USER" "$USER_HOME/.bash_profile"
chmod 644 "$USER_HOME/.bash_profile"
echo "✅ .bash_profile set up for autostart."


touch "$USER_HOME/.hushlogin"
set_ownership_and_perms "$USER_HOME/.hushlogin" 644

echo "⚙️ Configuring autologin to $TARGET_USER..."
sudo raspi-config nonint do_boot_behaviour B2
read -s -p "Enter a password for $TARGET_USER: " USER_PWD
echo
echo "$TARGET_USER:$USER_PWD" | sudo chpasswd
sudo mkdir -p /etc/systemd/system/getty@tty1.service.d

sudo bash -c "cat > /etc/systemd/system/getty@tty1.service.d/autologin.conf" <<EOF
[Service]
ExecStart=
ExecStart=-/sbin/agetty --autologin $TARGET_USER --noclear %I \$TERM
EOF

sudo systemctl daemon-reexec

echo "🔧 Configuring splash screen..."
sudo sed -i '/^disable_splash/d' /boot/config.txt
echo "disable_splash=1" | sudo tee -a /boot/config.txt
if [ -f Images/apple_splash.png ]; then
  sudo apt install -y plymouth plymouth-themes
  sudo cp Images/apple_splash.png /usr/share/plymouth/themes/pix/splash.png
fi

echo "🔐 Setting passwordless sudo for shutdown/reboot..."
if ! sudo grep -q "^$TARGET_USER.*NOPASSWD: /sbin/shutdown" /etc/sudoers; then
  echo "$TARGET_USER ALL=(ALL) NOPASSWD: /sbin/shutdown, /sbin/reboot" | sudo tee -a /etc/sudoers
fi


sudo rm -f /etc/systemd/system/getty@tty1.service.d/autologin.conf
sudo mkdir -p /etc/systemd/system/getty@tty1.service.d

sudo bash -c "cat > /etc/systemd/system/getty@tty1.service.d/autologin.conf" <<EOF
[Service]
ExecStart=
ExecStart=-/sbin/agetty --autologin $TARGET_USER --noclear %I \$TERM
EOF

echo "🚀 Launching Basilisk II to begin installation..."
sudo -u "$TARGET_USER" BasiliskII
echo "📴 Basilisk II has closed."
read -p "🕹️ Press Enter to continue setup..."

echo "📝 Writing Basilisk II Final prefs file..."
if [ -f "$PREFS_PATH" ]; then
  i=1
  while [ -f "$PREFS_PATH.bak.$i" ]; do
    i=$((i + 1))
  done
  cp "$PREFS_PATH" "$PREFS_PATH.bak.$i"
  echo "🔐 Backup created: $PREFS_PATH.bak.$i"
fi

: > "$PREFS_PATH"
cat <<EOF > "$PREFS_PATH"
rom $USER_HOME/macos8/LC575.ROM
disk $USER_HOME/macos8/macos8.img
extfs $USER_HOME/Downloads
screen dga/800/600
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
set_ownership_and_perms "$PREFS_PATH" 644

echo "📂 Copying InstallFiles into Downloads folder..."
if [ -d InstallFiles ]; then
  mkdir -p "$USER_HOME/Downloads/InstallFiles"
  cp -r InstallFiles/* "$USER_HOME/Downloads/InstallFiles/"
  chown -R "$TARGET_USER:$TARGET_USER" "$USER_HOME/Downloads/InstallFiles"
  echo "✅ Files copied to $USER_HOME/Downloads/InstallFiles."
else
  echo "⚠️ No InstallFiles directory found. Skipping copy step."
fi

echo "🔧 Fixing ownership of macos8 folder..."
chown -R "$TARGET_USER:$TARGET_USER" "$USER_HOME/macos8"
chmod -R u+rwX,g+rX,o+rX "$USER_HOME/macos8"

echo "🧹 Removing self build source..."
sleep 10
echo "🧹 Removing macemu build source..."
rm -rf "$PWD/macemu"
echo "✅ macemu source removed."

echo "🧹 Removing installer directory $INSTALLER_DIR..."
rm -rf "$INSTALLER_DIR"

echo "✅ Cleanup complete."

echo "🔧 Disabling noisy systemd boot messages in /boot/cmdline.txt..."
sudo sed -i 's/ quiet//g' /boot/cmdline.txt
sudo sed -i 's/ loglevel=0//g' /boot/cmdline.txt
sudo sed -i 's/$/ quiet loglevel=0/' /boot/cmdline.txt
echo "✅ Boot command line now suppresses console output while keeping splash."

echo "🔁 Re-applying autologin boot behavior..."
sudo raspi-config nonint do_boot_behaviour B2

echo "✅ Setup complete. Rebooting..."
sleep 5
sudo reboot
