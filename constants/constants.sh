#!/bin/bash

# =================================================
# Define directories
# =================================================
SCRIPT_PATH="$(readlink -f "${BASH_SOURCE[0]}")"
SCRIPT_DIR="$(cd "$(dirname -- "$SCRIPT_PATH")" && pwd)"
auto_maintenance_component_root_dir="$(cd "$SCRIPT_DIR/.." && pwd)"

# =================================================
# Fixed environment constants & runtime variables
# =================================================

load_modules(){
  local target_path="$1"
  shift
  local target_modules=("$@")

  for load_file in "${target_modules[@]}"; do
    # shellcheck disable=SC2154
    local target_file="${target_path}/${load_file}.sh"
    if [[ -f "$target_file" ]]; then
      # shellcheck disable=SC1090
      source "$target_file"
    else
      echo "[ERROR] $target_file が見つかりません。" >&2
      exit 1
    fi
  done
}

# =================================================
# Load libs for auto_maintenance
# =================================================
libs_path="$auto_maintenance_component_root_dir"/libs
target_libs=(
    "error"
    "log"
    "dry"
    "detect_platform"
    "detect_overlay"
    "overlay_mode_change"
    "yq_helpr"
    "lock"
)
load_modules "$libs_path" "${target_libs[@]}"

# ========================================
# Load modules
# ========================================
modules_path="$auto_maintenance_component_root_dir"/modules
target_modules=(
    "state_manager"
    "actions"
    "util_func"
)
load_modules "$modules_path" "${target_modules[@]}"

# =================================================
# Auto Maintenance constants
# =================================================
export AUTO_MAINTENANCE_LIB="/usr/local/lib/auto-maintenance"
export AUTO_MAINTENANCE_BIN="/usr/local/bin/auto-maintenance"
export AUTO_MAINTENANCE_TASKS_FILE="/etc/maintenance_tasks.yaml"
export AUTO_MAINTENANCE_SERVICE_FILE="/etc/systemd/system/auto-maintenance.service"
export AUTO_MAINTENANCE_TIMER_FILE="/etc/systemd/system/auto-maintenance.timer"

# =================================================
# Install / Overlay Maintenance state
# =================================================
# Persistent state file (must survive overlay)
export OVERLAY_STATE_FILE_DEFAULT="/var/lib/maintenance/state"
export MANTE_LOG="/var/log/maintenance/maintenance.log"
export MANTE_JSON="/var/log/maintenance/task_status.json"
mkdir -p /var/lib/maintenance /var/log/maintenance 

# Overlay Switch Command
export OVERLAY_CMD="/usr/bin/raspi-config"
export OVERLAY_SUBCMD="nonint"
export OVERLAY_OP="do_overlayfs"

# Overlay switch command values
# Values used by raspi-config overlayfs command
# (0 = overlay turn ON, 1 = overlay turn OFF)
export OVERLAY_TURN_OFF=1   # raspi-config: overlayfs OFF（書き込み有効）
export OVERLAY_TURN_ON=0    # raspi-config: overlayfs ON（RAM overlay / 保護）

# Overlay runtime state values (表示/状態判定用)
# Runtime state meaning (reported from system)
# (1 = overlay is ON, 0 = overlay is OFF)
export OVERLAY_ON=1     # 現在 overlay=ON
export OVERLAY_OFF=0    # 現在 overlay=OFF

# Operation states
export STATE_FAILED=-1
export STATE_NONE=0
export STATE_IN_PROGRESS=1
export STATE_DONE=2

# Overlay maintenance task runner
if [[ -f "${AUTO_MAINTENANCE_LIB}/modules/task_runner.sh" ]]; then
  export TASK_RUNNER="${AUTO_MAINTENANCE_LIB}/modules/task_runner.sh"
else
  export TASK_RUNNER="${auto_maintenance_component_root_dir}/modules/task_runner.sh"
fi
if [[ -f "$AUTO_MAINTENANCE_TASKS_FILE" ]]; then
  export TASKS_YAML="$AUTO_MAINTENANCE_TASKS_FILE"
else
  export TASKS_YAML="${auto_maintenance_component_root_dir}/maintenance_funcs/maintenance_tasks.yaml"
fi


# =================================================
# Branch
# =================================================
#BRANCH="main"
#BRANCH="release-test/2.0.0"
BRANCH="REV2.0.0-TEST"

TEST_BRANCH=(
    release-test/2.0.0
    REV2.0.0-TEST
)

is_test_branch() {
  local b
  for b in "${TEST_BRANCH[@]}"; do
    [[ "$BRANCH" == "$b" ]] && return 0
  done
  return 1
}

if is_test_branch; then
  BRANCH_TYPE="test"
else
  BRANCH_TYPE="prod"
fi

# Overlay maintenance constants
case "${BRANCH_TYPE:-prod}" in
  test)
    # for test / release-test
    export COOLDOWN=3000   # 50min (50 * 60)
    ;;
  prod)
    # for production release
    export COOLDOWN=86400  # 24h
    ;;
  *)
    echo "[WARN] unknown BRANCH_TYPE=${BRANCH_TYPE}, fallback to prod"
    export COOLDOWN=86400
    ;;
esac

export STATE=0
export DONE_AT=


