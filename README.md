[![Shell CI](https://github.com/Tetsuya1126/raspi_overlay-auto-update/actions/workflows/shellcheck.yml/badge.svg)](https://github.com/Tetsuya1126/raspi_overlay-auto-update/actions/workflows/shellcheck.yml)

# 🚀 Raspberry Pi OverlayFS Auto Update

Automatic unattended updates for Raspberry Pi running OverlayFS read-only mode.

Temporarily disables OverlayFS, performs apt upgrades safely,
then restores read-only mode automatically.

> Raspberry Pi OverlayFS 環境で、安全に自動アップデートを行うためのメンテナンスフレームワークです。

---

## 📌 Why This Project?

When Raspberry Pi uses OverlayFS (read-only mode):

- `apt upgrade` changes are lost after reboot
- automatic updates are difficult
- maintenance often requires manual reboot steps


Many simple update scripts temporarily remount the root filesystem as read-write.
However, in long-term unattended systems using OverlayFS, writable layers can gradually fill up, causing failures or instability.

This project intentionally uses a reboot-based update flow:

1. Enter writable update mode
2. Apply updates safely
3. Reboot automatically
4. Start with a clean overlay state

This prioritizes long-term reliability over short-term convenience.

This project automates the entire workflow safely.

> OverlayFS利用時の面倒な手動更新作業を自動化します。

---
## ✨ Features

### Core
- 🔄 Automatic OverlayFS ON/OFF switching
- 🔁 Safe reboot-based maintenance workflow
- 🔧 Custom task definitions via YAML

### Reliability
- 🛡 Prevents duplicate runs with lock control
- ❄ Cooldown interval protection
- ⚠ Continue processing even if one task fails
- 💾 Smart /boot/firmware remount handling for kernel upgrades
- ⏱ systemd timer automation
- ✅ Real-world tested for months

### Developer Friendly
- 🧪 Dry-run mode for safe testing
- 📄 JSON task result logs
- 🚦 GitHub Actions CI

> OverlayFS環境で通常の `apt upgrade` が永続保存されない問題を解決します。

---

## ⚠️ Official releases are published only in this repository.

**Any third-party archives or mirrored packages are unverified and unsupported.**
**We do not distribute ZIP archives, EXE files, or third-party mirrors.**

---

## ⚡ Quick Install

### Method 1: Git Clone

```bash
git clone https://github.com/Tetsuya1126/raspi_overlay-auto-update.git
cd raspi_overlay-auto-update
sudo ./install/install.sh
```

### Method 2: One-Line Installer

```bash
curl -fsSL https://raw.githubusercontent.com/Tetsuya1126/raspi_overlay-auto-update/v2.0.0-beta1/install/install.sh | sudo bash
```

> Downloads and runs the official installer directly from GitHub.

### If `curl` is not installed:

```bash
sudo apt-get update
sudo apt-get install curl -y
```

> 約3分で導入可能です。

---

## 📁 Installed Files

| Type | Path |
|------|------|
| Main library | `/usr/local/lib/auto-maintenance/` |
| Executable link | `/usr/local/bin/auto-maintenance/maintenance.sh` |
| Service | `/etc/systemd/system/auto-maintenance.service` |
| Timer | `/etc/systemd/system/auto-maintenance.timer` |
| Config | `/etc/maintenance_tasks.yaml` |
| State file | `/var/lib/maintenance/state` |
| Logs | `/var/log/maintenance/` |

---

## 🔄 How It Works

### Maintenance Flow

```text
Timer Start
   ↓
maintenance.sh
   ↓
Lock Check
   ↓
Detect Raspberry Pi / PC
   ↓
Read Current State
   ↓
OverlayFS Mode Check
   ↓
Choose Action
   ↓
Reboot if Needed
   ↓
Run Maintenance Tasks
   ↓
Restore OverlayFS ON
```

---

## 🎯 Actions

| Action | Description |
|-------|-------------|
| `NEED_OVERLAY_OFF` | Reboot into Overlay OFF mode |
| `DO_MAINTENANCE` | Execute maintenance tasks |
| `MAINTENANCE_CONTINUE` | Resume interrupted maintenance |
| `RESUME_TO_OVERLAY_OFF` | Recover previous interrupted state |
| `COOL_DOWN` | Skip run during cooldown period |
| `IDLE` | Initial / neutral state |

---

## 🧪 Dry Run Mode

Test safely without reboot or Overlay changes:

```bash
sudo maintenance.sh --dry
```

Dry-run behavior:

- No reboot
- No Overlay switch
- Logs only
- State file updates

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
**apt_update.sh ; Smart Raspberry Pi Boot Partition Handling**

During kernel / firmware upgrades, this project temporarily remounts `/boot/firmware` as read-write and restores read-only mode automatically.

---

## ⏱ systemd Timer Example

```ini
[Timer]
OnCalendar=Sun,Thu *-*-* 04:00:00
RandomizedDelaySec=300
Persistent=true
```

Enable:

```bash
sudo systemctl daemon-reload
sudo systemctl enable --now auto-maintenance.timer
```

Check:

```bash
systemctl list-timers
```

---

## 🧩 Cooldown Control

Default value is defined in: `/usr/local/lib/auto-maintenance/constants/constants.sh`

```bash
COOLDOWN=86400
```

(24 hours)

This prevents excessive SD card writes and repeated maintenance runs.

---

## 📄 Logs

### Main Log

```bash
cat /var/log/maintenance/maintenance.log
```

### Task JSON Result

```bash
cat /var/log/maintenance/task_status.json
```

Example:

```json
{"task":"apt_upgrade","result":"success","time":"2026-05-03"}
```

---

## 🔐 Duplicate Run Protection

If another process is already running:

```text
[warn] Another maintenance.sh already running → exit
```

---

## 🧯 Troubleshooting

| Problem | Cause | Fix |
|--------|------|-----|
| Infinite reboot loop | Broken state file | Remove state file |
| No maintenance run | Cooldown active | Wait or reduce cooldown |
| Stuck in resume mode | Overlay toggle failed | Manually set OFF then reboot |

---

## ✅ Tested Environments

- Raspberry Pi 2 Model B
- Raspberry Pi Zero
- Raspberry Pi 3 Model B+
- Raspberry Pi 3 Model B (QEMU)
- Raspberry Pi OS
- Raspbian Trixie
- Debian Bullseye
- VirtualBox test environment

> 数ヶ月の実運用実績あり。

---

## 🚦 CI

GitHub Actions:

- shellcheck
- bash syntax check (`bash -n`)

---

## 🛣 Roadmap

- Retry logic for Overlay switching
- Auto recovery from FAILED state
- Release package builds
- Web dashboard (future)

---

## 🤝 Contributions

Issues / Pull Requests welcome.

---

## ✅ Status

beta1 release for establish Stable release for general use.

---

## 📄 License

MIT License

---

## 🏛️ Official Repository

**This is the original actively maintained repository with tested installation steps.**
### **If this project helps you, please star this repository.**
**Reliable updates for read-only Raspberry Pi systems.**



