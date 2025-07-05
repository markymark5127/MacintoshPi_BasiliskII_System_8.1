# 🍎 Vintage Mac OS 8.1 Kiosk on Raspberry Pi 5

This project turns a Raspberry Pi 5 (8GB recommended) running Raspberry Pi OS 64-bit (Lite or Desktop) into a **fullscreen, kiosk-style vintage Macintosh** booting directly into **Mac OS 8.1** using Basilisk II.

Designed for **kids** (or nostalgic adults!), it offers **auto-boot**, **auto-shutdown**, **hotkeys**, **multiple disk support**, and **optional Minecraft Pi Edition Reborn integration**.

---

## 💻 Features

- ✅ One-command setup via `setup.sh`
- 🧱 Builds Basilisk II emulator from source
- 📍 Dynamically creates & mounts `macos8.img`
- 👢 Includes helper script to add *more drives* anytime
- 🎮 Optional Minecraft Pi Edition Reborn integration
- 💾 True fullscreen-only kiosk mode
- 🔊 Sound support (ALSA)
- 🖱️ Auto-hides the mouse cursor
- 💡 Prevents screen blanking & sleep
- ⌘ Hotkeys for **reboot** and **shutdown** with retro splash overlays
- 🛡️ Auto-shutdown if Basilisk II exits unexpectedly
- ✅ Cleans up install source after setup

---

## 🚀 Quick Install

Run these commands on your Raspberry Pi 5 (running Raspberry Pi OS 64-bit):

```bash
git clone https://github.com/markymark5127/MacintoshPi_BasiliskII_System_8.1.git
cd MacintoshPi_BasiliskII_System_8.1
chmod +x setup.sh
sudo ./setup.sh         # Add --with-minecraft for Pi Edition Reborn support
```

The installer:

- Installs all dependencies
- Builds Basilisk II from source
- Copies all necessary files to the user's home
- Configures automatic console login & fullscreen X session
- Optionally integrates Minecraft

---

## 📆 Installed Layout

After running `setup.sh`, your user’s home will contain:

```
~/macos8/
    LC575.ROM
    macos8.img
    DiskTools_MacOS8.image
    MacOS8_1.iso
    DriveParts/
    add_macos8_drive.sh
    shutdown.png
    reboot.png
```

✅ Also:

- `~/.basilisk_ii_prefs`
- `~/launch_wrapper.sh`
- `~/.bash_profile` for auto-launch on login

---

## 🛠️ How It Works

On boot:

1⃣ Raspberry Pi auto-logins to console.\
2⃣ Runs X with **.xinitrc**, which calls **launch\_wrapper.sh**.\
3⃣ **launch\_wrapper.sh** supervises kiosk behavior:

✅ Runs Basilisk II in fullscreen\
✅ Watches for triggers:

- `.launch_minecraft` in **\~/Downloads** → Launches Minecraft Pi Reborn
- `.shutdown` or `.reboot` in home → Shows overlay splash & powers off or reboots ✅ Waits 5 seconds after Basilisk II exits:
- If no trigger → assumes user chose **shutdown** and powers off the Pi automatically.

---

## 🋡️ Kiosk Supervisor (launch\_wrapper.sh)

Handles all switching:

- Auto-restarts Basilisk II unless a shutdown or reboot is requested.
- If user quits Basilisk II without rebooting:
  - Waits 5 seconds.
  - If nothing triggers → automatically shuts down.
- Minecraft integration:
  - `.launch_minecraft` file in **\~/Downloads** triggers Minecraft Reborn.
  - On exit → returns to Basilisk II.

---

## ⌘️ Hotkeys (Inside Basilisk II)

| Key Combo        | Action          |
| ---------------- | --------------- |
| `Ctrl + Alt + S` | Shutdown system |
| `Ctrl + Alt + R` | Reboot system   |

✅ Both show a fullscreen retro splash before powering off.

---

## 👇️ Add Extra Drives Anytime

Included:

```
~/macos8/add_macos8_drive.sh
```

🌟 Lets you:

- Build additional disk images from included `DriveParts`.
- Name them whatever you want.
- Automatically appends the new `disk` line to your Basilisk II prefs.

Perfect for adding more classic Mac software disks at any time!

---

## 🎮 Optional: Minecraft Pi Edition Reborn

If you run:

```bash
sudo ./setup.sh --with-minecraft
```

✅ Installs Flatpak & MCPI Reborn.\
✅ Sets up:

- `.launch_minecraft` trigger in **\~/Downloads** to launch Minecraft from within Mac OS.
- Copies a launcher into the emulated Mac’s Applications folder.

🌟 Kids can click Minecraft on the Mac desktop → instantly switches to the native Pi game.

---

## 🖼️ Custom Splash Screens

Your own images can replace:

- `Images/shutdown.png`
- `Images/reboot.png`

✅ Must be **800x600+** PNGs.\
✅ Shown fullscreen before shutdown or reboot.

---

## 📂 Shared Folder Access

Your Pi’s:

```
~/Downloads/
```

is mounted inside the emulator as the **Unix** drive.

✅ Simple drag-and-drop file transfer between Raspberry Pi and Mac OS 8.1.

---

## ⚡️ Requirements

- Raspberry Pi 5 (8GB recommended)
- Raspberry Pi OS 64-bit Lite or Desktop
- Internet access for installation
- At least 4–8 GB free on SD card

---

## 👶 Designed For Kids

Created for a 5-year-old to safely explore vintage Mac OS:

- Simple, distraction-free fullscreen-only kiosk
- Retro-style Apple splash overlays
- Auto-shutdown when closed, for safety and ease of use

---

## 💡 Inspiration

- Macintosh LC 575 and 68k all-in-one Macs
- Kid Pix, Millie’s Math House, Bailey’s Book House
- The MacintoshPi project
- kanjitalk755’s Basilisk II fork

---

## 📜 License

This project is provided *as-is* for personal, educational, and nostalgic use only.\
✅ Ensure you own the rights to any Apple ROMs or software you use.

---

## ❤️ Special Thanks

- [kanjitalk755](https://github.com/kanjitalk755/macemu) for Basilisk II
- Archive.org and Macintosh Garden for preserving classic software
- The retro Mac community keeping 68k alive 🔥🍏

