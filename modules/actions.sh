#!/bin/bash
set -e

# -------------------------------------------------
# action functions for handling different platform actions
# -------------------------------------------------
action_raspi_only() {
  case "$ACTION" in
    NEED_OVERLAY_OFF)
      log_info "Entering maintenance mode. $ACTION"
      disabling_overlay_mode
      ;;
    RESUME_TO_OVERLAY_OFF)
      log_info "Reentering maintenance mode. $ACTION"
      disabling_overlay_mode
      ;;
    DO_MAINTENANCE)
      log_info "Run maintenance tasks. $ACTION"
      run_maintenance
      done_after_maintenance
      ;;
    MAINTENANCE_CONTINUE)
      log_info "Continuing maintenance tasks. $ACTION"
      run_maintenance
      done_after_maintenance
      ;;
    IDLE)
      log_info "Run maintenance tasks. $ACTION"
      run_maintenance
      done_after_maintenance
      ;;
    COOL_DOWN)
      log_info "Stay. $ACTION"
      ;;
    *)
      log_info "No action defined. $ACTION"
      ;;
  esac
}

action_pc_only() {
  log_info "PC detected: skipping overlay switch actions"

  #log_info "Dry run mode"
  #export DRY=true

  case "$ACTION" in
    DO_MAINTENANCE | MAINTENANCE_CONTINUE | IDLE)
      log_info "Run maintenance tasks. $ACTION"
      run_maintenance
      ;;
    NEED_OVERLAY_OFF | RESUME_TO_OVERLAY_OFF)
      log_info "Stay, Irregular $ACTION"
      ;;
    COOL_DOWN)
      log_info "Stay. $ACTION"
      ;;
    *)
      log_info "No action defined. $ACTION"
      ;;
  esac
}
