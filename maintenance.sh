#!/bin/bash
set -e

# =================================================
# Require root
# =================================================
if [[ $EUID -ne 0 ]]; then
    echo "[ERROR] sudo で実行してください" >&2
    exit 1
fi

# =================================================
# Define directories
# =================================================
SCRIPT_PATH="$(readlink -f "${BASH_SOURCE[0]}")"
SCRIPT_DIR="$(cd -- "$(dirname -- "$SCRIPT_PATH")" && pwd)"
auto_maintenance_component_root_dir="$SCRIPT_DIR"

# ========================================
# Load Component Constants
# ========================================
CONSTANTS_FILE="${auto_maintenance_component_root_dir}/constants/constants.sh"
if [[ -f "$CONSTANTS_FILE" ]]; then
    # shellcheck disable=SC1090
    source "$CONSTANTS_FILE"
else
    echo "[ERROR] $CONSTANTS_FILE が見つかりません。" >&2
    exit 1
fi

# ========================================
# Main Function
# ========================================

# ==== Lock機構 ====
# LOCK 初期化
lock_init

# acquire lock
if ! lock_acquire "maintenance"; then
    log_warn "Another maintenance.sh already running → exit"
    exit 0
fi
trap 'lock_release' EXIT

# ==== state 初期化 ====
state_init

# ==== dry run 判定 ====
dry_run_mode "$@"     #  ← ★ 追加：コマンドライン引数から DRY 判定

# ==== メンテナンス状態確認 ====
ACTION=$(get_action)
log_info "Decided ACTION=$ACTION"

# ==== メンテナンス実行 ====
if is_pc; then
  action_pc_only
else
  action_raspi_only
fi
