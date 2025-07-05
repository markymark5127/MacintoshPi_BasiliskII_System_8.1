# 🍎 Vintage Mac OS 8.1 Kiosk on Raspberry Pi 5

This project transforms a Raspberry Pi 5 (8GB) running Raspberry Pi OS 64-bit Desktop into a **fullscreen, kiosk-style vintage Macintosh** running **Mac OS 8.1** via Basilisk II. It supports sound, auto-boot, hotkeys for shutdown/reboot, and includes a curated library of classic Mac software.

---

## 💻 Features

- 🔧 One-command setup via `setup.sh`
- 🧱 Builds Basilisk II emulator from source (kanjitalk755 fork)
- 💽 Dynamically creates `macos8.img` as a sparse file using available SD card space
- 🎮 Preloaded with classic Mac games and educational apps (optional)
- 🖥️ Fullscreen-only mode (distraction-free for kids)
- 🔊 Sound support via ALSA
- 🐁 Auto-hides the mouse cursor
- 🛌 Prevents screen blanking and sleep
- ⌨️ Hotkeys for reboot (`Ctrl+Alt+R`) and shutdown (`Ctrl+Alt+S`) with retro-style overlay screens
- ✅ Post-install prompt finalizes setup and removes install media
- 📁 Mounts Pi’s `~/Downloads/` into Mac as “Unix” drive
- 🧱 Optional Minecraft Pi Edition Reborn integration (desktop launcher inside Mac)

---

### 🚀 Quick Install

Execute the commands below on a Raspberry Pi running Raspberry Pi OS 64‑bit. This clones the repo and runs the setup script in one shot:

```bash
git clone https://github.com/markymark5127/MacintoshPi_BasiliskII_System_8.1.git \
  && cd MacintoshPi_BasiliskII_System_8.1 \
  && sudo ./setup.sh   # add --with-minecraft if you want Pi Edition Reborn
```
The installer handles all dependencies and will automatically copy the `Minecraft` launcher into the emulated Mac if you use the `--with-minecraft` flag.


## 📦 Included Files

| File/Folder                | Description                                               |
|---------------------------|-----------------------------------------------------------|
| `setup.sh`                | Main setup script                                         |
| `BasiliskII.install.prefs`| Prefs for initial install mode (floppy + CD + HDD)        |
| `BasiliskII.final.prefs`  | Prefs for final boot mode (just the HDD)                  |
| `LC575.ROM`               | Macintosh Quadra ROM file                                 |
| `DiskTools_MacOS8.image`  | Boot floppy used for installation                         |
| `MacOS8_1.iso.part_*`     | Split ISO parts (joined automatically)                    |
| `Images/shutdown_MacBackground.png`            | 800×600+ fullscreen image shown before shutdown           |
| `Images/reboot_MacBackground.png`              | 800×600+ fullscreen image shown before reboot             |
| `shutdown_overlay.sh`     | Script: show shutdown image and power off                 |
| `reboot_overlay.sh`       | Script: show reboot image and restart                     |
| `InstallFiles/`           | Apps auto-copied to `macos8.img/Applications`             |
| `Minecraft/` | If `--with-minecraft` flag: `.launch_minecraft` → Applications, `Minecraft` app → Desktop (Pi Edition Reborn) |

---

## 🛠 Requirements

- Raspberry Pi 5 (8GB recommended)
- Raspberry Pi OS 64-bit Lite (Kernel 6.1+)
- Internet access for setup
- A microSD card with 4–8 GB or more free space

---

## 🚀 Setup Instructions

1. Clone the project:
   ```bash
   git clone https://github.com/markymark5127/MacintoshPi_BasiliskII_System_8.1.git
   cd MacintoshPi_BasiliskII_System_8.1
   ```

2. Make the script executable:
   ```bash
   chmod +x setup.sh
   ```

3. Run the setup script (optionally add Minecraft Pi Edition Reborn support):
   ```bash
   sudo ./setup.sh       # pass --with-minecraft to include the game
   ```
   The script automatically installs files into the account that invoked `sudo`,
   so running it with `sudo` is sufficient.

4. The installer configures console autologin and `startx` so the emulator boots
   straight into fullscreen mode on each restart.

5. Inside the emulator, initialize the new disk and complete the OS installation.

6. When the emulator is closed, return to the terminal and press ENTER to copy extra applications and finalize setup (removes CD/floppy and reboots into your installed Mac OS 8.1 system).

---

## ⌨️ Hotkeys

| Key Combo        | Action           |
|------------------|------------------|
| `Ctrl + Alt + S` | Shutdown system  |
| `Ctrl + Alt + R` | Reboot system    |

Each action displays a retro-style fullscreen overlay image before execution.

---

## 📋 Customization

- To include more Mac apps:  
  Drop `.sit`, `.img`, or `.app` files into the `InstallFiles/` folder before running `setup.sh`.

- To customize the reboot/shutdown visuals:  
  Replace `Images/shutdown_MacBackground.png` and `Images/reboot_MacBackground.png` with your own **800x600+** PNG images.

---

### 🔧 Preinstalled Tools (from `InstallFiles/`)

- 🛠 **ResEdit 2.1.1**
- 📄 **Adobe Acrobat 3.0**
- 💾 **Disk Copy 4.2**
- 📦 **StuffIt Expander 5.5**

---

### 🎨 Custom Overlay Templates (`images/` Folder)

| File                        | Description                            |
|-----------------------------|----------------------------------------|
| `MacBackground.png`         | Clean 800×600 background base          |
| `shutdown_MacBackground.png`| Example shutdown image                 |
| `reboot_MacBackground.png`  | Example reboot image                   |
| `Message_MacBackground.png` | Template with text overlay             |

---

## 📂 Shared Folder Access

The Raspberry Pi’s `~/Downloads/` folder is mounted inside the emulator — drop files there from the Pi and access them within Mac OS using tools like `Disk Copy` or `StuffIt`.

---

## 👶 Who’s It For?

This project was built for a 5-year-old to explore vintage Macintosh games and software in a safe, simplified, and focused environment — no modern OS distractions.

---

## 💡 Inspiration

- Apple Macintosh LC 575 and all-in-one 68k machines
- Kid Pix, Millie’s Math House, Bailey’s Book House
- The MacintoshPi and Mini vMac projects

---

## 📜 License

This project is provided as-is for personal, educational, and nostalgic use. Please ensure you own licenses for any Apple software and ROMs used with it.

---

## ❤️ Special Thanks

- [kanjitalk755](https://github.com/kanjitalk755/macemu) for maintaining Basilisk II
- Archive.org and Macintosh Garden for preserving vintage software
- Everyone in the retro Mac community keeping the 68k flame alive 🔥🍏
