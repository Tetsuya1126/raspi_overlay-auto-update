#!/bin/bash
set -euo pipefail

# ================= 設定 =================
STATE_FILE="/var/lib/.overlay_update_state"
LOG="/var/log/overlay_auto_update.log"
OVERLAY_CMD="/usr/bin/raspi-config nonint do_overlayfs"
COOLDOWN=86400    # 24時間
DRY_RUN=false

# 新Pi対応LED
LED="/sys/class/leds/PWR"
LED_ERR="/sys/class/leds/ACT"

exec >> "$LOG" 2>&1

# ===== options =====
for arg in "$@"; do
  case "$arg" in
    --dry-run)
      DRY_RUN=true
      echo "[OPTION] DRY-RUN enabled"
      ;;
  esac
done


# ================= LED functions =================
led_mmc0() {
  echo mmc0 > "$LED/trigger"
}

led_fast_blink() {
  echo timer > "$LED/trigger"
  echo 100 > "$LED/delay_on"
  echo 100 > "$LED/delay_off"
}

led_slow_blink() {
  echo timer > "$LED/trigger"
  echo 500 > "$LED/delay_on"
  echo 500 > "$LED/delay_off"
}

led_on() {
  echo none > "$LED/trigger"
  echo 1 > "$LED/brightness"
}

apply_led_state() {
  case "$STAGE" in
    0)
      led_fast_blink   # overlay OFF準備
      ;;
    1)
      led_mmc0         # アップデート中
      ;;
    2)
      led_slow_blink   # overlay 復帰中
      ;;
    *)
      led_on
      ;;
  esac
}

error_blink() {
  CODE=$1

  echo none > "$LED_ERR/trigger"

  while true; do
    for i in $(seq 1 $CODE); do
      echo 1 > "$LED_ERR/brightness"
      sleep 0.2
      echo 0 > "$LED_ERR/brightness"
      sleep 0.2
    done
    sleep 2
  done
}


# ================= main =================
die() {
  CODE=$1
  echo "[ERROR] Fail code $CODE"
  error_blink "$CODE"
  #cleanup
}

cleanup() {  
  # ===== 完了処理 =====
  #rm -f "$STATE_FILE" || true
  #systemctl stop overlay-auto-update.timer
  #systemctl stop overlay-auto-update.service
  led_on
  exit 0
}

set_stage() {
  STAGE=$1  # 変数も更新
  echo "STAGE=$1" > "$STATE_FILE"
  sync
  apply_led_state
  sleep 2
}

record_done() {
  echo "STAGE=2" > "$STATE_FILE"
  echo "DONE_AT=$(date +%s)" >> "$STATE_FILE"
  sync
  sleep 2
}

apt_upgrade() {
  # apt update & upgrade
  export DEBIAN_FRONTEND=noninteractive

  if $DRY_RUN; then
    echo "[DRY] apt-get update"
    echo "[DRY] apt-get -y upgrade"
    echo "[DRY] apt-get -y autoremove"
    return 0
  fi

  apt-get update || die 1
  apt-get -y upgrade || die 2
  apt-get -y autoremove
}

is_overlay() {
  findmnt -n -o FSTYPE / | grep -qx overlay
}

get_overlay_status() {
  OVERLAY_ON=false
  is_overlay && OVERLAY_ON=true
}

get_last_stage() {
  if [ -f "$STATE_FILE" ]; then
    # ファイルがシェル形式で書かれている場合は source で読み込む
    # 空白や改行があっても OK
    # shellcheck disable=SC1090
    . "$STATE_FILE"
    
    # STAGE が未設定ならデフォルト 0
    : "${STAGE:=0}"
    # DONE_AT が未設定なら空
    : "${DONE_AT:=}"
  else
    STAGE=0
    DONE_AT=
  fi
}

switch_overlay() {
  if $DRY_RUN; then
    echo "[DRY] switch_overlay $1"
    return 0
  fi

  $OVERLAY_CMD "$1" || die 3
  sync
  sleep 2
}

cooldown() {
#  ELAPSED=$(( $(date +%s) - DONE_AT ))
#  if [ "$ELAPSED" -ge "$COOLDOWN" ]; then
  if is_in_cooldown; then
    echo "[FLOW] Cooldown active -> skip update"
    exit 0
  else
    echo "[FLOW] Cooldown passed -> reset STAGE to 0 for re-update"
    STAGE=0
  fi

}

is_in_cooldown() {
  [ -n "$DONE_AT" ] && \
  [ $(( $(date +%s) - DONE_AT )) -lt "$COOLDOWN" ]
}

do_reboot() {
  if $DRY_RUN; then
    echo "[DRY] reboot skipped"
    return 0
  fi
  reboot
}



#
# ---- メイン制御 ----
#

get_last_stage
get_overlay_status
echo "=== START overlay=${OVERLAY_ON} stage=${STAGE} $(date) ==="


# ==== クールダウン期間確認 ====
if [ "$STAGE" -eq 2 ] && [ -n "$DONE_AT" ]; then
  cooldown
fi

# ==== 未完了フェーズ ====
if [ "$STAGE" -lt 2 ]; then

  # Overlay が有効なら OFF にして再起動
  if $OVERLAY_ON; then
    echo "[FLOW] overlay ON & stage <2 -> disable overlay & reboot"
    set_stage 0 || die 4
    switch_overlay 1
    do_reboot
    exit 0
  fi

  # RW環境なので apt 実行可能
  echo "[FLOW] RW mode -> apt upgrade"

  set_stage 1 || die 4
  apt_upgrade
  set_stage 2 || die 4

  do_reboot
  exit 0

fi

# ==== 完了フェーズ ====
if [ "$STAGE" -ge 2 ]; then

  # 完了後も overlay OFF のままなら戻す
  if ! $OVERLAY_ON; then
    echo "[FLOW] stage >=2 & overlay OFF -> restore overlay"
    record_done
    switch_overlay 0
    do_reboot
    exit 0
  fi

  echo "[FLOW] update already completed"
  cleanup

fi


#状態	PWR　LED
#通常運用	点灯
#STAGE 0 → OFF 準備	速い点滅
#STAGE 1 → アップデート中	SD activity
#STAGE 2 → Overlay 復帰中	　ゆっくり点滅
#完了	連続点灯　元の状態に戻す


#エラーコード	点滅パターン	意味
#E1	1回点滅 → 長休止	apt update 失敗
#E2	2回点滅 → 長休止	apt upgrade 失敗
#E3	3回点滅 → 長休止	overlay 切替失敗
#E4	4回点滅 → 長休止	スクリプト異常終了