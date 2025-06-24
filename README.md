# 🍎 Vintage Mac OS 8.1 Kiosk on Raspberry Pi 5

This project transforms a Raspberry Pi 5 (8GB) running Raspberry Pi OS 64-bit Lite into a **fullscreen, kiosk-style vintage Macintosh** running **Mac OS 8.1** via Basilisk II. It supports sound, auto-boot, hotkeys for shutdown/reboot, and includes a curated library of classic Mac software.

---

## 💻 Features

- 🔧 One-command setup via `setup.sh`
- 🧱 Builds Basilisk II emulator from source (kanjitalk755 fork)
- 💽 Dynamically creates `macos8.img` using available SD card space
- 🎮 Preloaded with classic Mac games and educational apps (optional)
- 🖥️ Fullscreen-only mode (distraction-free for kids)
- 🔊 Sound support via ALSA
- 🐁 Auto-hides the mouse cursor
- 🛌 Prevents screen blanking and sleep
- ⌨️ Hotkeys for reboot (`Ctrl+Alt+R`) and shutdown (`Ctrl+Alt+S`) with retro-style overlay screens
- ✅ Post-install prompt finalizes setup and removes install media
- 📁 Mounts Pi’s `~/Downloads/` into Mac as “Unix” drive
- 🧱 Optional Minecraft Pi Edition integration (desktop launcher inside Mac)

---

## 📦 Included Files

| File/Folder                | Description                                               |
|---------------------------|-----------------------------------------------------------|
| `setup.sh`                | Main setup script                                         |
| `BasiliskII.install.prefs`| Prefs for initial install mode (floppy + CD + HDD)        |
| `BasiliskII.final.prefs`  | Prefs for final boot mode (just the HDD)                  |
| `LC575.ROM`               | Macintosh Quadra ROM file                                 |
| `DiskTools_MacOS8.image`  | Boot floppy used for installation                         |
| `MacOS8_1.iso.part_*`     | Split ISO parts (joined automatically)                    |
| `shutdown.png`            | 800×600+ fullscreen image shown before shutdown           |
| `reboot.png`              | 800×600+ fullscreen image shown before reboot             |
| `shutdown_overlay.sh`     | Script: show shutdown image and power off                 |
| `reboot_overlay.sh`       | Script: show reboot image and restart                     |
| `InstallFiles/`           | Apps auto-copied to `macos8.img/Applications`             |
| `InstallFiles/Minecraft/` | If `--with-minecraft` flag: `.launch_minecraft` → Applications, `Minecraft` app → Desktop |

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
   git clone https://github.com/yourusername/macos8-raspi-setup.git
   cd macos8-raspi-setup
   ```

2. Make the script executable:
   ```bash
   chmod +x setup.sh
   ```

3. Run the setup script (optionally add Minecraft support):
   ```bash
   sudo ./setup.sh --with-minecraft
   ```

4. After reboot, Mac OS 8.1 will launch in fullscreen automatically.

5. Inside the emulator, complete the OS installation normally.

6. When prompted in the terminal, press ENTER to finalize setup (removes CD/floppy and reboots into your installed Mac OS 8.1 system).

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
  Replace `shutdown.png` and `reboot.png` with your own **800x600+** PNG images.

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
