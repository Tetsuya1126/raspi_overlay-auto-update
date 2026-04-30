#!/bin/bash

# =================================================
# Define directories
# =================================================
SCRIPT_PATH="$(readlink -f "${BASH_SOURCE[0]}")"
SCRIPT_DIR="$(cd "$(dirname -- "$SCRIPT_PATH")" && pwd)"
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


apt_update() {
  apt-get update -y
  apt-get upgrade -y
  apt-get autoremove -y
}

# =================================================
# Main
# =================================================

if is_raspberry_pi; then
  echo "[INFO] rasberry pi mode"
  mount -o remount,rw /boot/firmware
  apt_update
  mount -o remount,ro /boot/firmware
else
  echo "[INFO] PC mode"
  apt_update
fi




    
