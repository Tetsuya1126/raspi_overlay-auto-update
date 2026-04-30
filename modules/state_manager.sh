#!/bin/bash
set -e

# ---- Init ----
state_init() {
  STATE_FILE="${STATE_FILE:-$OVERLAY_STATE_FILE_DEFAULT}"
}

# ---- Load saved state ----
state_load() {
  if [[ -f "$STATE_FILE" ]]; then
    # shellcheck disable=SC1090
    source "$STATE_FILE"
  else
    STATE=$STATE_NONE
    DONE_AT=0
  fi
}

# ---- Save state ----
state_set() {
  local new_state="$1"
  STATE="$new_state"
  echo "STATE=$new_state" > "$STATE_FILE"
  echo "DONE_AT=$(date +%s)" >> "$STATE_FILE"
  sync
  sleep 2
}

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

# ---- Decide action ----
# RETURN VALUES:
#   NEED_OVERLAY_OFF
#   DO_MAINTENANCE
#   COOL_DOWN
#   RESUME_TO_OVERLAY_OFF
#   MAINTENANCE_CONTINUE
#   IDLE

#Overlay State	Action Name	                 意味
# ON	    2 	  NEED_OVERLAY_OFF/COOL_DOWN   maintenance modeに入るために次回起動後Overlay OFF。ただし、cooldown期間判定あり
# ON	    1	    RESUME_TO_OVERLAY_OFF        maintenance mode に入り直す。（auto maintenanceが途中で止まってOvelayONの状態） 
# ON	    0	    NEED_OVERLAY_OFF             初回起動でstate記録なし、OvelayOFF後IDLEへ以降
# OFF	    2	    DO_MAINTENANCE/COOL_DOWN     auto maintenance可能。auto maintenance完了後overlay ON に戻す。ただし、cooldown期間判定あり/cooldown中はauto-maintenanceは走らず手動メンテ可能
# OFF	    1	    MAINTENANCE_CONTINUE         auto maintenance作業動作中 継続
# OFF	    0	    IDLE                         初回起動でstate記録なし

state_decide_action() {
  local overlay="$1"   # OVERLAY_ON / OFF
  local state="$2"     # STATE_NONE / IN_PROGRESS / DONE
  local done_at="$3"   # timestamp (epoch)
  
  if [[ "$overlay" -eq $OVERLAY_ON ]]; then
    # shellcheck disable=SC2153
    case "$state" in
      "$STATE_DONE")
        if state_is_cooldown_elapsed "$done_at"; then
          echo "COOL_DOWN"
        else
          echo "NEED_OVERLAY_OFF"
        fi
        ;;
      "$STATE_IN_PROGRESS"|"$STATE_FAILED")
        echo "RESUME_TO_OVERLAY_OFF"
        ;;
      "$STATE_NONE")
        echo "NEED_OVERLAY_OFF"
        ;;
    esac

  else
    case "$state" in
      "$STATE_DONE")
        if state_is_cooldown_elapsed "$done_at"; then
          echo "COOL_DOWN"
        else
          echo "DO_MAINTENANCE"
        fi
        ;;
      "$STATE_IN_PROGRESS"|"$STATE_FAILED")
        echo "MAINTENANCE_CONTINUE"
        ;;
      "$STATE_NONE")
        echo "IDLE"
        ;;
    esac
  fi
}

get_action() {
  overlay_is_enabled && ov=$OVERLAY_ON || ov=$OVERLAY_OFF
  state_load

  action=$(state_decide_action "$ov" "$STATE" "$DONE_AT")
  echo "$action"
}
