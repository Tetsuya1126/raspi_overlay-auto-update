#!/bin/bash
set -e
# =================================================
# Define directories
# =================================================
SCRIPT_PATH="$(readlink -f "${BASH_SOURCE[0]}")"
SCRIPT_DIR="$(cd -- "$(dirname -- "$SCRIPT_PATH")" && pwd)"
auto_maintenance_component_root_dir="$(cd "$SCRIPT_DIR/../" && pwd)"

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

run_task() {
  local NAME="$1"
  local CMD="$2"

  log_info "[TASK] $NAME started $(date)" | tee -a "$LOG"

  if dry_eval "$CMD" >> "$LOG" 2>&1; then
    RESULT="success"
  else
    RESULT="fail"
    ((ERROR++))
  fi

  echo "{\"task\":\"$NAME\",\"result\":\"$RESULT\",\"time\":\"$(date)\"}," >> "$JSON"
  echo "[TASK] $NAME => $RESULT" | tee -a "$LOG"
}

main() {
  # --- YAML を読み込み & 実行 ---
  count=$(yq_get "tasks | length" "$TASKS_YAML")

  for i in $(seq 0 $((count - 1))); do
    NAME=$(yq_get "tasks[$i].name" "$TASKS_YAML")
    CMD=$(yq_get "tasks[$i].cmd" "$TASKS_YAML")
    run_task "$NAME" "$CMD"
  done

  # --- 最終ログ ---
  SUCCESS=$((count - ERROR))
  {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] [INFO] Task Summary: $SUCCESS/$count succeeded, $ERROR failed"
    echo
   } | tee -a "$LOG"

  # --- exit code ---
  if ((ERROR > 0)); then
    return 1
  else
    return 0
  fi
}


LOG=$MANTE_LOG
JSON=$MANTE_JSON
ERROR=0  # fail 件数

# --- テスト用環境変数があれば上書き ---
if [[ -n "${TEST_TASKS_YAML:-}" ]]; then
    echo  "[INFO] Using test environment variables"
    TASKS_YAML="$TEST_TASKS_YAML"
    LOG="$TEST_MANTE_LOG"
    JSON="$TEST_MANTE_JSON"
fi

dry_run_mode "$@"   # dry run mode 初期化

main
RET=$?
exit $RET