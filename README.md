# 🚀 Raspberry Pi OverlayFS Auto Update

**Fix the problem: *“apt upgrade disappears after reboot”* on OverlayFS systems.**

Fully automated, reboot-safe maintenance framework for **read-only Raspberry Pi environments**.

> Designed for long-term unattended systems — stable, safe, and hands-free.

---

⭐ **If this project helps you, consider giving it a star!**

---

## 🎯 Who is this for?

* Raspberry Pi running in **read-only (OverlayFS) mode**
* Devices deployed in the field (IoT / edge / remote systems)
* Systems that must run **unattended for months**
* Anyone tired of **manual update + reboot workflows**

---

## 💥 What problem does this solve?

On OverlayFS systems:

* `apt upgrade` changes **disappear after reboot**
* Writable layer can **fill up over time**
* Manual maintenance becomes **fragile and risky**

---

## ✅ The Solution

This project introduces a **reboot-based maintenance workflow**:

1. Switch to writable mode
2. Apply updates safely
3. Reboot automatically
4. Restore clean read-only OverlayFS

✔ No manual steps
✔ No broken updates
✔ No overlay corruption

---

## ✨ Key Features

### 🔄 Fully Automated

* Automatic OverlayFS ON/OFF switching
* systemd timer-based execution
* Zero manual intervention

### 🛡 Built for Reliability

* Reboot-based safe update design
* Lock mechanism (prevents duplicate runs)
* Cooldown protection (avoids excessive writes)
* Resume support after interruption
* Self-healing state recovery (fallback to safe state)

### 🔧 Flexible & Extensible

* YAML-based task definitions
* Custom scripts supported
* JSON logging for automation

### 🧪 Developer Friendly

* Dry-run mode (no reboot / safe testing)
* GitHub Actions CI (shellcheck + syntax validation)

---

## ⚡ Quick Start (under 3 minutes)

Install and enable automatic maintenance in one step:

### One-line install

```bash
curl -fsSL https://raw.githubusercontent.com/Tetsuya1126/raspi_overlay-auto-update/v2.0.0-rc/install/install_curl.sh | sudo bash
```

---

### Or manual install

```bash
git clone --branch v2.0.0-rc --depth 1 https://github.com/Tetsuya1126/raspi_overlay-auto-update.git
cd raspi_overlay-auto-update
sudo ./install/install.sh
```

---

> ⚠️ Always install from the official GitHub repository to ensure safety.

---

## 🔍 How It Works

```text
Timer Start
   ↓
maintenance.sh
   ↓
Lock Check
   ↓
State Detection
   ↓
OverlayFS Mode Check
   ↓
Reboot if Needed
   ↓
Run Tasks (apt, custom scripts)
   ↓
Restore OverlayFS (read-only)
   ↓
Wait for next scheduled run
```

---

## 🧪 Safe Testing (Dry Run)

```bash
sudo maintenance.sh --dry
```

* No reboot
* No OverlayFS changes
* Logs only

---

## 🛠 Task Configuration

Edit:

```bash
sudo nano /etc/maintenance_tasks.yaml
```

Example:

```yaml
tasks:
  - name: apt_update
    cmd: /usr/local/lib/auto-maintenance/maintenance_funcs/apt_update.sh

  - name: custom_script
    cmd: bash /usr/local/bin/myscript.sh
```

---

## 🔄 State Transitions (Simplified)

| Overlay | State | Action                       |
| ------- | ----- | ---------------------------- |
| ON      | 2     | NEED_OVERLAY_OFF / COOL_DOWN |
| ON      | 1     | RESUME_TO_OVERLAY_OFF        |
| ON      | 0     | NEED_OVERLAY_OFF (initial)   |
| OFF     | 2     | DO_MAINTENANCE / COOL_DOWN   |
| OFF     | 1     | MAINTENANCE_CONTINUE         |
| OFF     | 0     | IDLE                         |

---

## 💡 State File Handling

The system relies on a persistent state file.

* Missing or corrupted state will reset to a safe default (`STATE=0`)
* Maintenance will restart automatically from a clean state
* Designed to recover from interruptions without manual intervention

---

## 📄 Logs

```bash
/var/log/maintenance/maintenance.log
/var/log/maintenance/task_status.json
```

---

## 🔐 Security Notice

Official releases are **only published in this repository**.

We do NOT distribute:

* ZIP archives
* EXE files
* Third-party mirrors

If you find this project elsewhere, treat it as untrusted.

---

## 🧩 Tested Environments

* Raspberry Pi 2 / 3 / Zero
* Raspberry Pi OS / Debian
* QEMU / VirtualBox

✔ Real-world tested for months

---

## 🛣 Roadmap

* Retry logic for Overlay switching
* Automatic recovery from failed states

---

## 📚 Documentation

See Wiki for detailed usage (Keep on update):
https://github.com/Tetsuya1126/raspi_overlay-auto-update/wiki

---

## 🤝 Contributing

Issues and Pull Requests are welcome.

---

## 📄 License

MIT License

---

## 🏁 Status

**v2.0.0-rc — Release candidate for real-world usage**

---

## 🏛 Official Repository

**This is the original upstream repository.**

Actively used in real-world deployments and maintained as needed.

Reliable updates for read-only Raspberry Pi systems.

---

Keywords: Raspberry Pi OverlayFS auto update safe upgrade systemd.