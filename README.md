# 🧰 Auto Maintenance System (overlay-aware)

maintenance.sh は Raspberry Pi OverlayFS を対象にした**安全な自動メンテナンス**を提供するスクリプトです。

## Beta Release

This branch contains version 2 beta.

Status:
- Test release
- Behavior/output may still change
- Recommended for testers only

For stable production use:
- use `main`

## ⌨インストール方法

```bash
git clone git@github.com:Tetsuya1126/raspi_overlay-auto-update
cd raspi_overlay-auto-update/
sudo ./install/install.sh
```

default導入先：
ライブラリ一式
```
/usr/local/lib/auto-maintenance/
```
実行ファイル(リンク)
```
/usr/local/bin/auto-maintenance/maintenance.sh
```
サービスファイル
```
/etc/systemd/system/auto-maintenance.service
/etc/systemd/system/auto-maintenance.timer
```
設定ファイル
```
/etc/maintenance_tasks.yaml
```

***インストール後***
```
maintenance_tasks.yaml
auto-meintenance.timer
COOLDOWN
```

の設定を確認をしてください

## ⏩State & Actions
OverlayFS で Overlay OFF時に確実にmaintenance 実行するため、

以下の仕組みを採用します：

|Action	| 意味 |
|-------|------|
| NEED_OVERLAY_OFF      | Overlay OFF設定後再起動、次回はOverlayOFF |
| COOL_DOWN             | CoolDown期間中、何もせず終了              |
| DO_MAINTENANCE        | run_maintenance / 完了後、Overlay ON設定後再起動|
| MAINTENANCE_CONTINUE  | run_maintenance (続き)/特殊ケース         |
| RESUME_TO_OVERLAY_OFF | run_maintenance (続き)/特殊ケース         |
| IDLE                  | 初回 起動直後/特殊ケース                  |



## 📌 動作概要
```
auto-maintenance.timer
auto-maintenance.service
→ maintenance.sh
  └─ lock_acquire により多重起動制御
  └─ detect_platform により PC / RaspberryPi を判定
  └─ state_manager.sh で 状態(state) を読み込み/Action決定
       ├─ STATE_NONE / IN_PROGRESS / DONE / FAILED
       ├─ DONE_AT タイムスタンプ管理
       └─ COOL_DOWN 判定
  Action(NEED_OVERLAY_OFF/COOLDOWN/DO_MAINTENANCE)
  └─ overlay_mode_change により Overlay切替
  └─ util_func.sh / run_maintenance により作業実行
```

## 🚦 実行フロー図
```bash
$ sudo maintenance.sh
```
フロー
```
pc/raspi判定
　 PC    → maintenance only (overlay判定なし)
 　raspi → RaspberryPi処理
     ▼
load state (STATE, DONE_AT)
overlay mode判定
cooldown判定
     ▼
ACTION 決定 
  NEED_OVERLAY_OFF     → overlay OFF のため再起動待ち
  RESUME_TO_OVERLAY_OFF→ 途中中断 → 再入場
  DO_MAINTENANCE       → run_maintenance
  MAINTENANCE_CONTINUE → run_maintenance (続き)
  COOL_DOWN            → 何もせず終了
  IDLE                 → 初回 起動直後
     ▼
ACTION毎の指定動作
```

Overlay/Stateの状態とActionの関係
| Overlay | State | Action Name                  | 意味                                                                                     |
|---------|-------|------------------------------|------------------------------------------------------------------------------------------|
| ON      | 2     | NEED_OVERLAY_OFF/COOL_DOWN   | maintenance modeに入るために次回起動後Overlay OFF。ただし、cooldown期間判定あり          |
| ON      | 1     | RESUME_TO_OVERLAY_OFF        | maintenance mode に入り直す。（auto maintenanceが途中で止まってOvelayONの状態）           |
| ON      | 0     | NEED_OVERLAY_OFF             | 初回起動でstate記録なし、OvelayOFF後IDLEへ以降                                           |
| OFF     | 2     | DO_MAINTENANCE/COOL_DOWN     | auto maintenance可能。auto maintenance完了後overlay ON に戻す。ただし、cooldown期間判定あり/cooldown中はauto-maintenanceは走らず手動メンテ可能 |
| OFF     | 1     | MAINTENANCE_CONTINUE         | auto maintenance作業動作中 継続                                                          |
| OFF     | 0     | IDLE                         | 初回起動でstate記録なし                                                                  |


## 🧪 Dry Run（安全確認モード）
```bash
$ sudo maintenance.sh --dry
```
DRY=true の場合：
```
overlay切替は行わない
rebootしない
run_maintenance() は実行ログのみ表示
state ファイルは書き換える
```

## 📁 主なファイル
```
auto-maintenance/
 ├─ maintenance.sh           ← メインスクリプト
 ├─ README.md
 ├─ LICENCE
 ├─ modules
 ｜   ├─ state_manager.sh    ← State判定
 ｜   ├─ actions.sh   　　　 ← Action実行
 ｜   ├─ util_func.sh    　　← ユーティリティー
 ｜   └─ task_runner.sh    　← メンテタスク実行ヘルパ
 ├─ libs　                   ← ライブラリ関数
 ├─ constants/constants.sh　　　　　　← 定数定義
 ├─ configs/maintenance_tasks.yaml　　← メンテタスク定義
 ├─ maintenance_funcs/apt_update.sh　 ← タスク例
 └─ install　　　　　　　　　　　　　 ← インストール関連
```

## 🔐 Lock 機構

多重起動を避けるため、毎回 lock を取得します：

```bash
# ---------------------------------------
# Lock機構
# ---------------------------------------
# LOCK 初期化
lock_init

# acquire lock
if ! lock_acquire "maintenance"; then
    log_warn "Another maintenance.sh already running → exit"
    exit 0
fi
trap 'lock_release' EXIT
```

すでに動作中なら:
```
[warn] Another maintenance.sh already running → exit
```

## 🧽 State 保持ファイル

デフォルト保存先：
```
/var/lib/maintenance/state
```

```
export OVERLAY_STATE_FILE_DEFAULT="/var/lib/maintenance/state"
```
で設定

変数例：
```
STATE=DONE
DONE_AT=1735682340
```

Operation States定義
```
export STATE_FAILED=-1
export STATE_NONE=0
export STATE_IN_PROGRESS=1
export STATE_DONE=2
```

COOLDOWN 判定：
```bash
# --------------------------------------------
# return 0 = cooldown elapsed (実行可能)
# return 1 = still cooling down (まだ実行不可)
# --------------------------------------------
state_is_cooldown_elapsed() {
  local done_at="$1"

  # done_at が無い or 0 の場合は即 elapsed 判定
  if [[ -z "$done_at" || "$done_at" -le 0 ]]; then
    return 0
  fi

  [ -n "$done_at" ] && [ $(( $(date +%s) - done_at )) -lt "$COOLDOWN" ]
}
```

### 🛠 run_maintenance の中で行う作業の設定例
/etc/maintenance_tasks.yaml に記載
```yaml
tasks:
  - name: apt_update
    cmd: sudo apt-get update -y

  - name: apt_upgrade
    cmd: sudo apt-get upgrade -y

  - name: cleanup
    cmd: sudo apt-get autoremove -y

  - name: xray_rotate_check
    cmd: bash /usr/local/bin/xray_utils/policy_check.sh
```

## ⏱ COOLDOWN時間の設定例
auto-maintenance/constants/constants.sh
```bash
export COOLDOWN=86400    # 24時間
```
COOLDOWN定数で設定

## 🧩 systemd 自動実行設定例
TimerがServiceを呼ぶ設定

### 設定ファイル
/etc/systemd/system/auto-maintenance.timer
```
[Unit]
Description=Daily overlay maintenance executor

[Timer]
Unit=auto-maintenance.service
OnCalendar=Sun,Thu *-*-* 04:00:00
RandomizedDelaySec=300
Persistent=true

[Install]
WantedBy=timers.target
```

/etc/systemd/system/auto-maintenance.service
```
[Unit]
Description=Auto Maintenance w/ overlay toggle
After=network.target

[Service]
Type=oneshot
ExecStart=/usr/local/bin/auto-maintenance/maintenance.sh
RemainAfterExit=no
```

有効化：
```bash
sudo systemctl daemon-reload
sudo systemctl reset-failed auto-maintenance.service
sudo systemctl reset-failed auto-maintenance.timer
sudo systemctl enable --now auto-maintenance.timer
```

### Timerの待機確認
```bash
systemctl list-timers 
NEXT                            LEFT LAST                              PASSED UNIT                         ACTIVATES                     
Sat 2026-01-03 17:00:00 JST    25min Sat 2026-01-03 16:30:00 JST 4min 51s ago auto-maintenance.timer       auto-maintenance.service

10 timers listed.
Pass --all to see loaded but inactive timers, too.
```
auto-maintenance.timerがあることを確認

### 起動順序
- NEXTのタイミングでtimer発火 -> service起動

- Reboot後も自動発火


## ❗注意事項
### 手動メンテ時の制限事項
- 通常運用では OverlayFS が有効であることを前提としています。
- 手動で保守作業を行う場合、Overlay を外すために再起動が必要がですが、
　前回のauto-maintenanceからCOOLDOWN時間（デフォルト24時間）が過ぎていると
　auto-maintenance が実行され、Overlay FS が自動で復帰します。
- これは仕様であり、SD 書き込み保護の安全性を保証するためです。
- COOLDOWN時間内であれば、auto-maintenance処理はスキップされます。
- 初回インストール時も同様の理由で自動的にOverlay FS が自動で復帰します。
　継続して手動保守を行うには、数回、Overlay OFFの操作を繰り返す必要があります。
- 保守中に Overlay を外したまま作業を行う場合、保守経過時間によって
  一時的に Overlay が戻ることがあります。

## 🧯 トラブル対処

| 状況 | 原因 | 対処 |
|------|------|------|
|action が RESUME_TO_OVERLAY_OFF のまま	| Overlay 切替が壊れて停止 | 手動で off → reboot |
| 無限ループ  | state が壊れた | /var/lib/overlay_state を一旦削除 |
| maintenance 実行しない | COOL_DOWN に入っている | COOLDOWN 秒設定確認 |

## 🧪 Debug Tips
```
sudo systemctrl start auto-meintenance.service
journalctl -u auto-maintenance.service -f -n 50
cat /var/log/maintenance/maintenance.log
cat /var/log/maintenance/task_status.json
cat /var/lib/maintenance/state

sudo systemctrl list-timers
sudo systemctrl list-jobs
```

## ✏️ TODO

overlay_mode_change のリトライ処理

FAILED 状態からの自動リカバリ

## 📄License

MIT

## ✅ 動作確認済環境
Raspberry Pi 2 Model B
```
uname -a
Linux raspberrypi 6.12.47+rpt-rpi-v7 #1 SMP Raspbian 1:6.12.47-1+rpt1 (2025-09-16) armv7l GNU/Linux

cat /sys/firmware/devicetree/base/model 
Raspberry Pi 2 Model B Rev 1.2

cat /etc/os-release 
PRETTY_NAME="Raspbian GNU/Linux 13 (trixie)"
NAME="Raspbian GNU/Linux"
VERSION_ID="13"
VERSION="13 (trixie)"
VERSION_CODENAME=trixie
DEBIAN_VERSION_FULL=13.1
ID=raspbian
ID_LIKE=debian
HOME_URL="http://www.raspbian.org/"
SUPPORT_URL="http://www.raspbian.org/RaspbianForums"
BUG_REPORT_URL="http://www.raspbian.org/RaspbianBugs"

cat /proc/cpuinfo  
Hardware	: BCM2835
Revision	: a22042
Serial		: 00000000f5bf5248
Model		: Raspberry Pi 2 Model B Rev 1.2
```

raspiOS on VirtualBox
```
uname -a
Linux raspberry 5.10.0-36-amd64 #1 SMP Debian 5.10.244-1 (2025-09-29) x86_64 GNU/Linux

cat /etc/os-release 
PRETTY_NAME="Debian GNU/Linux 11 (bullseye)"
NAME="Debian GNU/Linux"
VERSION_ID="11"
VERSION="11 (bullseye)"
VERSION_CODENAME=bullseye
ID=debian
HOME_URL="https://www.debian.org/"
SUPPORT_URL="https://www.debian.org/support"
BUG_REPORT_URL="https://bugs.debian.org/"

cat /proc/cpuinfo 
processor	: 0
vendor_id	: GenuineIntel
cpu family	: 6
model		: 151
model name	: 12th Gen Intel(R) Core(TM) i7-12700
stepping	: 2
microcode	: 0x3a
cpu MHz		: 2111.998
cache size	: 25600 KB
physical id	: 0
siblings	: 1
core id		: 0
cpu cores	: 1
apicid		: 0
initial apicid	: 0
fpu		: yes
fpu_exception	: yes
cpuid level	: 22
wp		: yes
flags		: fpu vme de pse tsc msr pae mce cx8 apic sep mtrr pge mca cmov pat pse36 clflush mmx fxsr sse sse2 ht syscall nx rdtscp lm constant_tsc rep_good nopl xtopology nonstop_tsc cpuid tsc_known_freq pni pclmulqdq monitor ssse3 fma cx16 pcid sse4_1 sse4_2 x2apic movbe popcnt aes xsave avx f16c rdrand hypervisor lahf_lm abm 3dnowprefetch invpcid_single pti fsgsbase bmi1 avx2 bmi2 invpcid rdseed adx clflushopt sha_ni arat md_clear flush_l1d arch_capabilities
bugs		: cpu_meltdown spectre_v1 spectre_v2 spec_store_bypass l1tf mds swapgs itlb_multihit rfds its
bogomips	: 4223.99
clflush size	: 64
cache_alignment	: 64
address sizes	: 46 bits physical, 48 bits virtual
power management:
```

Raspberry Pi 3 Model B on QEMU
``` 
uname -a
Linux raspberrypi 5.4.51-v8+ #1333 SMP PREEMPT Mon Aug 10 16:58:35 BST 2020 aarch64 GNU/Linux

cat /sys/firmware/devicetree/base/model 
Raspberry Pi 3 Model B

cat /etc/os-release
PRETTY_NAME="Debian GNU/Linux 10 (buster)"
NAME="Debian GNU/Linux"
VERSION_ID="10"
VERSION="10 (buster)"
VERSION_CODENAME=buster
ID=debian
HOME_URL="https://www.debian.org/"
SUPPORT_URL="https://www.debian.org/support"
BUG_REPORT_URL="https://bugs.debian.org/"

cat /proc/cpuinfo
processor	: 0
BogoMIPS	: 125.00
Features	: fp asimd evtstrm aes pmull sha1 sha2 crc32 cpuid
CPU implementer	: 0x41
CPU architecture: 8
CPU variant	: 0x0
CPU part	: 0xd03
CPU revision	: 4

processor	: 1
BogoMIPS	: 125.00
Features	: fp asimd evtstrm aes pmull sha1 sha2 crc32 cpuid
CPU implementer	: 0x41
CPU architecture: 8
CPU variant	: 0x0
CPU part	: 0xd03
CPU revision	: 4

processor	: 2
BogoMIPS	: 125.00
Features	: fp asimd evtstrm aes pmull sha1 sha2 crc32 cpuid
CPU implementer	: 0x41
CPU architecture: 8
CPU variant	: 0x0
CPU part	: 0xd03
CPU revision	: 4

processor	: 3
BogoMIPS	: 125.00
Features	: fp asimd evtstrm aes pmull sha1 sha2 crc32 cpuid
CPU implementer	: 0x41
CPU architecture: 8
CPU variant	: 0x0
CPU part	: 0xd03
CPU revision	: 4

Hardware	: BCM2835
Model		: Raspberry Pi 3 Model B

```

他、raspiZEROでも動作

---




