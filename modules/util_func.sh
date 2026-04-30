#!/bin/bash
set -e

run_maintenance() {
  # Dry Runはtask runnner内で処理する/stateは変更
  state_set "$STATE_IN_PROGRESS"

  # run task runner
  bash "$TASK_RUNNER"
  RET=$?
  
  if [ "$RET" -eq 0 ]; then
    # ---- Success ----
    log_info "Maintenance completed"
    state_set "$STATE_DONE"
  else
    # ---- Error handling ----
    log_error "Maintenance FAILED (exit=$RET)"
    state_set "$STATE_FAILED"
    #return 1      # ← 上位(main)に失敗を伝える
  fi
  
  sync
  sleep 2
  #return 0
}

done_after_maintenance() {
  if $DRY; then
    log_info "[DRY] restore overlay=ON and reboot skipped"
    return 0
  fi

  log_info "Maintenance finished → restore overlay=ON"
  overlay_on
  do_reboot 
}

disabling_overlay_mode() {
  if $DRY; then
    log_info "[DRY] Switching overlay=OFF and reboot skipped"
    return 0
  fi

  log_info "Switching overlay=OFF → reboot"
  overlay_off
  do_reboot
}

do_reboot() {
  if $DRY; then
    log_info "[DRY] reboot skipped"
    return 0
  fi

  log_info "Rebooting system..."
  sync
  sleep 2
  reboot
}
