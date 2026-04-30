# OverlayFS Safe Auto Update
[![Shell CI](https://github.com/Tetsuya1126/raspi_overlay-auto-update/actions/workflows/shellcheck.yml/badge.svg)](https://github.com/Tetsuya1126/raspi_overlay-auto-update/actions/workflows/shellcheck.yml)

Safe automatic system update framework for Raspberry Pi using OverlayFS.

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
```bash
git clone https://github.com/Tetsuya1126/raspi_overlay-auto-update.git
cd raspi_overlay-auto-update
sudo bash install.sh
```

---

## Dry Run
動作確認モード:

```bash
sudo overlay-auto-update.sh --dry-run
```

実際のシステム変更・overlay切替・reboot は行われません。
そのため、overlayの状態により実際の動作が異なります。

---

## Configuration
実行スケジュールは以下で変更可能：
```bash
sudo nano /etc/systemd/system/overlay-auto-update.timer
```

---

## CI
GitHub Actions で shellcheck + bash -n による自動検証を行っています。

---

## Requirements
Debian / Ubuntu / Raspberry Pi OS
systemd
OverlayFS enabled

---

## 注意事項（保守時の挙動）

- 通常運用では OverlayFS が有効であることを前提としています。
- 手動で保守作業を行う場合、Overlay を外すために再起動が必要がですが、
　前回のauto-updateからCOOLDOWN時間（デフォルト24時間）が過ぎていると
　auto-update が実行され、Overlay FS が自動で復帰します。
- これは仕様であり、SD 書き込み保護の安全性を保証するためです。
- COOLDOWN時間内であれば、auto-update処理はスキップされます。
- 保守中に Overlay を外したまま作業を行う場合、保守経過時間によって
  一時的に Overlay が戻ることがあります。

---

## LED状態表
状態表示
PWR LED 赤LED
- 通常運用	点灯
- STAGE 0 → OFF 準備	速い点滅
- STAGE 1 → アップデート中	SD activity
- STAGE 2 → Overlay 復帰中	　ゆっくり点滅
- 完了	連続点灯　元の状態に戻す

エラー表示
ACT LED 緑LED　
エラーコード	点滅パターン	意味
- E1	1回点滅 → 長休止	apt update 失敗
- E2	2回点滅 → 長休止	apt upgrade 失敗
- E3	3回点滅 → 長休止	overlay 切替失敗
- E4	4回点滅 → 長休止	スクリプト異常終了

---

## Watchdog
このスクリプトは systemd の built-in watchdog 機能を前提としています。

Enable watchdog
1. モジュールロード
```bash
sudo modprobe bcm2835_wdt
echo bcm2835_wdt | sudo tee /etc/modules-load.d/watchdog.conf
```

2. systemd 有効化

/etc/systemd/system.conf

RuntimeWatchdogSec=15

ShutdownWatchdogSec=15

```bash
sudo systemctl daemon-reexec
```

3. watchdogd 無効化

```bash
sudo systemctl disable watchdog
sudo systemctl stop watchdog
```

4. Verify
```bash
systemctl show | grep Watchdog
```

確認項目：

ServiceWatchdogs=yes

WatchdogDevice=/dev/watchdog0

---

Keywords: Raspberry Pi OverlayFS auto update safe upgrade systemd watchdog.
