#!/bin/bash

# overlayroot を ON/OFF 切替するスクリプト

overlay_on() {
  echo "[INFO] Turning overlay ON"
  "$OVERLAY_CMD" "$OVERLAY_SUBCMD" "$OVERLAY_OP" "$OVERLAY_TURN_ON" || return 1
  systemctl daemon-reload || return 1
}

overlay_off() {
  echo "[INFO] Turning overlay OFF"
  "$OVERLAY_CMD" "$OVERLAY_SUBCMD" "$OVERLAY_OP" "$OVERLAY_TURN_OFF" || return 1
  systemctl daemon-reload || return 1
}

switch_overlay() {
  case "${1:-}" in
    "$OVERLAY_TURN_ON") overlay_on ;;
    "$OVERLAY_TURN_OFF") overlay_off ;;
    *) echo "[ERROR] Invalid parameter for switch_overlay: $1"
       echo "usage: $0 {$OVERLAY_TURN_ON|$OVERLAY_TURN_OFF} {OVERLAY_TURN_ON|OVERLAY_TURN_OFF}" ; exit 1;;
  esac 
}



