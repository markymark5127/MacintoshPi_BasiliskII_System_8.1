# 🍎 Vintage Mac OS 8.1 Kiosk on Raspberry Pi 5

This project turns a Raspberry Pi 5 (8GB) running Raspberry Pi OS 64-bit Lite into a **fully self-contained, fullscreen, kiosk-style vintage Mac** running **Mac OS 8.1** via Basilisk II. It includes sound, keyboard shutdown/reboot hotkeys, auto-boot, and a curated collection of classic Mac games and educational software.

---

## 💻 Features

- 🔧 One-command setup script (`setup.sh`)
- 🍏 Basilisk II emulator builds from source
- 📀 Automatically generates large `macos8.img` based on available SD card space
- 🎮 Pre-installed classic Mac games and educational software
- 🗄️ Fullscreen-only mode (no desktop)
- 🔊 Sound support with ALSA
- 🐁 Auto-hiding mouse cursor
- 🛌 Prevents screen blanking and sleep
- ⌨️ Hotkeys for reboot (`Ctrl+Alt+R`) and shutdown (`Ctrl+Alt+S`) with retro-style fullscreen overlays
- ✅ Prompts to finalize setup after install, and cleans up boot media and prefs

---

## 📦 Included Files

| File/Folder                | Description                                        |
|---------------------------|----------------------------------------------------|
| `setup.sh`                | Main script — run once to set everything up        |
| `BasiliskII.install.prefs`| Initial config (boots floppy + CD + HDD)           |
| `BasiliskII.final.prefs`  | Final config (boots only the installed system)     |
| `LC575.ROM`               | Macintosh ROM file (Quadra 650 or similar)         |
| `DiskTools_MacOS8.image`  | Boot floppy for Mac OS 8.1 installer               |
| `MacOS8_1.iso.part_*`     | ISO split files (reassembled on Pi)                |
| `shutdown.png`            | Fullscreen image shown before power-off           |
| `reboot.png`              | Fullscreen image shown before reboot              |
| `shutdown_overlay.sh`     | Script to show image and shut down                 |
| `reboot_overlay.sh`       | Script to show image and reboot                    |
| `InstallFiles/`           | Optional apps/games auto-copied to `macos8.img`    |

---

## 🛠 Requirements

- Raspberry Pi 5 (8GB recommended)
- Raspberry Pi OS 64-bit Lite (Kernel 6.1+)
- Internet access on first boot for setup
- A microSD card with at least 4–8 GB free

---

## 🚀 Setup Instructions

1. Clone the project:
   ```bash
   git clone https://github.com/yourusername/macos8-raspi-setup.git
   cd macos8-raspi-setup
   ```

2. Make the setup script executable:
   ```bash
   chmod +x setup.sh
   ```

3. Run the setup:
   ```bash
   ./setup.sh
   ```

4. After reboot, Mac OS 8.1 will launch fullscreen automatically with installer loaded.

5. Complete the install inside Mac OS.

6. After installation, press ENTER in the terminal when prompted to finalize setup. This will remove the floppy and CD and reboot into your installed system.

---

## ⌨️ Hotkeys

| Key Combo        | Action           |
|------------------|------------------|
| `Ctrl + Alt + S` | Shutdown system  |
| `Ctrl + Alt + R` | Reboot system    |

Each shows a friendly fullscreen retro overlay image before acting.

---

## 📋 Customization

- To add more Mac apps, place `.sit`, `.img`, or `.app` files into `InstallFiles/`
- You can replace `shutdown.png` or `reboot.png` with your own 800x600+ pixel art

---

## 📂 Shared Folder

Your Raspberry Pi’s `~/Downloads` folder is mounted in the emulator — drag and drop files into it, then access them from within Mac OS.

---

## 😋 Who’s It For?

This project was built for a 5-year-old to safely and easily explore retro educational Mac software without needing to navigate modern OS interfaces.

---

## 💡 Inspiration

- Original Macintosh LC 575 form factor
- Classic Mac OS educational titles like Millie's Math House, Kid Pix, and Bailey's Book House
- The MacintoshPi and Mini vMac projects

---

## 📜 License

This project is provided as-is for educational and nostalgic purposes. Please ensure you own licenses for all Apple software and ROM files used.

---

## ❤️ Special Thanks

- Basilisk II contributors
- Archive.org Mac software preservation
- Retro tech nerds everywhere keeping 68k alive
