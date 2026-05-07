#!/bin/bash
set -euo pipefail

# =================================================
# Install script for auto-maintenance service
# =================================================
echo
echo "🚀 Starting installation of auto-maintenance..."
echo

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
# Ensure execute permissions for executable scripts
# =================================================
echo "[Install Project] Running chmod_exec.sh apply"
# chmod_exec を走らせる前に component_root_dir に移動
pushd "$auto_maintenance_component_root_dir" >/dev/null || exit
"$auto_maintenance_component_root_dir/libs/chmod_exec.sh" apply
popd >/dev/null || exit


# =================================================
# Install auto-maintenance scripts
# =================================================
# Prepare auto-maintenance  directory
mkdir -p "$AUTO_MAINTENANCE_BIN" "$AUTO_MAINTENANCE_LIB"

echo "[INFO] Installing auto-maintenance all scripts to $AUTO_MAINTENANCE_LIB"
# Copy files to lib directory
rsync -av \
    --exclude ".git" \
    --exclude ".vscode" \
    "$auto_maintenance_component_root_dir/" "$AUTO_MAINTENANCE_LIB"
# Set ouwnership to root
chown -R root:root "$AUTO_MAINTENANCE_LIB"


echo "[INFO] Installing executables to $AUTO_MAINTENANCE_BIN"
# Executable entrypoints to expose in bin
EXECUTABLES=(
  maintenance.sh
)
for f in "${EXECUTABLES[@]}"; do
  src="$AUTO_MAINTENANCE_LIB/$f"
  dst="$AUTO_MAINTENANCE_BIN/$f"

  if [[ -f "$src" ]]; then
    ln -sf "$src" "$dst"
  else
    echo "[WARN] skip: $src not found"
  fi
done


# Copy default maintenance tasks configuration if it doesn't exist
if [[ -f "$AUTO_MAINTENANCE_TASKS_FILE" ]]; then
  echo "[INFO] Existing config found"
  read -rp "Overwrite? [yes/No]: " ans </dev/tty || true
  if [[ "$ans" == "yes" ]]; then
    echo  "[INFO] Overwriting existing config with default config"
  else
    echo "[INFO] Backing up existing config to ${AUTO_MAINTENANCE_TASKS_FILE}.backup"  
    cp -a \
    "$AUTO_MAINTENANCE_TASKS_FILE" \
    "$AUTO_MAINTENANCE_TASKS_FILE.backup"
  fi
fi

echo "[INFO] Installing default maintenance tasks configuration"

install -Dm644 \
  "$AUTO_MAINTENANCE_LIB/configs/maintenance_tasks.yaml" \
  "$AUTO_MAINTENANCE_TASKS_FILE"


# =================================================
# Install auto-maintenance services
# =================================================
echo "[INFO] Installing overlay maintenance service"

install -Dm644 \
  "$AUTO_MAINTENANCE_LIB/install/service/auto-maintenance.service" \
  "$AUTO_MAINTENANCE_SERVICE_FILE"

case "${BRANCH_TYPE:-prod}" in
  test)
    # for test / release-test
    install -Dm644 \
      "$AUTO_MAINTENANCE_LIB/install/service/auto-maintenance_for_test.timer" \
      "$AUTO_MAINTENANCE_TIMER_FILE"
    ;;
  prod)
    # for production release
    install -Dm644 \
      "$AUTO_MAINTENANCE_LIB/install/service/auto-maintenance_for_prod.timer" \
      "$AUTO_MAINTENANCE_TIMER_FILE"
    ;;
  *)
    echo "[WARN] unknown BRANCH_TYPE=${BRANCH_TYPE}, fallback to prod"
    install -Dm644 \
      "$AUTO_MAINTENANCE_LIB/install/service/auto-maintenance_for_prod.timer" \
      "$AUTO_MAINTENANCE_TIMER_FILE"
    ;;
esac


systemctl daemon-reload
systemctl enable --now auto-maintenance.timer


# =================================================
# Post Installation
# =================================================
echo "✅ Installation completed successfully."

