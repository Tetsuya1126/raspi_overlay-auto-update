#!/bin/bash
set -euo pipefail

# =================================================
# Uninstall script for auto-maintenance service
# =================================================

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
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
auto_maintenance_component_root_dir="$(cd "$SCRIPT_DIR/.." && pwd)"

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

# =================================================
# Uninstall overlay maintenance service
# =================================================
echo "[INFO] Uninstalling overlay maintenance service"
systemctl disable --now auto-maintenance.timer || true
rm -f "$AUTO_MAINTENANCE_SERVICE_FILE"
rm -f "$AUTO_MAINTENANCE_TIMER_FILE"

systemctl daemon-reload

# =================================================
# Remove auto-maintenance files
# =================================================
echo "[INFO] Removing auto-maintenance files from $AUTO_MAINTENANCE_BIN"
rm -rf "$AUTO_MAINTENANCE_BIN"
rm -rf "$AUTO_MAINTENANCE_LIB"
rm -f "$AUTO_MAINTENANCE_TASKS_FILE"
rm -f "$AUTO_MAINTENANCE_TASKS_FILE.backup"


echo "[INFO] auto-maintenance uninstallation completed."