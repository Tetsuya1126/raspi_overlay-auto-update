# OverlayFS Safe Auto Update

Raspberry Pi / Debian 用  
OverlayFS 環境に対応した **安全な自動 apt 更新スクリプト**。

- 起動失敗時でも **overlay 保護**
- Stage 管理付き safe update
- reboot 制御
- systemd timer 実行
- ハング検出は global watchdog 使用

---

## Features
- OverlayFS 書き込み保護を維持したまま OS 更新
- 2 Stage update & reboot flow
- クールダウン抑制
- LED 状態通知
- 異常時 self recovery

---

## Install
sudo bash install.sh

---

## Dry Run
動作確認モード:
sudo overlay-auto-update.sh --dry-run

実際のシステム変更・overlay切替・reboot は行われません。

---

## Configuration
実行スケジュールは以下で変更可能：
sudo nano /etc/systemd/system/overlay-auto-update.timer

---

## CI
GitHub Actions で shellcheck + bash -n による自動検証を行っています。

---

## Requirements
Debian / Ubuntu / Raspberry Pi OS
systemd
OverlayFS enabled

---

## Watchdog
このスクリプトは systemd の built-in watchdog 機能を前提としています。

Enable watchdog
1. モジュールロード
sudo modprobe bcm2835_wdt
echo bcm2835_wdt | sudo tee /etc/modules-load.d/watchdog.conf

2. systemd 有効化
/etc/systemd/system.conf
RuntimeWatchdogSec=15
ShutdownWatchdogSec=15
sudo systemctl daemon-reexec

3. watchdogd 無効化
sudo systemctl disable watchdog
sudo systemctl stop watchdog

4. Verify
systemctl show | grep Watchdog

確認項目：
ServiceWatchdogs=yes
WatchdogDevice=/dev/watchdog0
