#!/bin/bash
# safe logging utility for bashlib
# works with set -u, set -e, overlay, and sudo

# -------------------------
# defaults
# -------------------------
: "${LOG_LEVEL:=info}"
: "${LOG_COLOR:=auto}"
: "${QUIET:=0}"
: "${LOG_DIR:=/tmp/bashlib_log}"  # デフォルト書き込み先

# -------------------------
# create log dir safely
# -------------------------
if [[ ! -w "$LOG_DIR" ]]; then
    LOG_DIR="$HOME/.local/share/bashlib/log"
fi
mkdir -p "$LOG_DIR" 2>/dev/null || true

# -------------------------
# level map
# -------------------------
declare -gA __LOG_LEVELS=(
  [debug]=0
  [info]=1
  [warn]=2
  [error]=3
)

__log_level_num="${__LOG_LEVELS[$LOG_LEVEL]:-1}"

# -------------------------
# color setup
# -------------------------
__use_color=0
if [[ "$LOG_COLOR" == "always" ]]; then
  __use_color=1
elif [[ "$LOG_COLOR" == "auto" && -t 2 ]]; then
  __use_color=1
fi

if (( __use_color )); then
  __CLR_DEBUG="\033[36m"  # cyan
  __CLR_INFO="\033[32m"   # green
  __CLR_WARN="\033[33m"   # yellow
  __CLR_ERROR="\033[31m"  # red
  __CLR_RESET="\033[0m"
else
  __CLR_DEBUG=""
  __CLR_INFO=""
  __CLR_WARN=""
  __CLR_ERROR=""
  __CLR_RESET=""
fi

# -------------------------
# internal logger
# -------------------------
__log() {
  local level="${1:-info}"  # デフォルト info
  shift
  local msg="$*"
  local lvl_num="${__LOG_LEVELS[$level]:-1}"
  (( lvl_num < __log_level_num )) && return 0
  (( QUIET )) && [[ "$level" != "error" ]] && return 0

  local color_var="__CLR_${level^^}"
  local color="${!color_var:-}"  # 未定義でも安全

  # safe printing
  printf "%b[%s] %s%b\n" "$color" "$level" "$msg" "$__CLR_RESET" >&2

  # safe file logging
  mkdir -p "${LOG_DIR:-/tmp/bashlib_log}" 2>/dev/null || true
  echo "[${level}] $msg" >> "${LOG_DIR:-/tmp/bashlib_log}/info.log" 2>/dev/null || true
}

# -------------------------
# public API
# -------------------------
log_debug() { __log debug "$@"; }
log_info()  { __log info  "$@"; }
log_warn()  { __log warn  "$@"; }
log_error() { __log error "$@"; }

# -------------------------
# sudo-safe wrapper
# -------------------------
sudo_log_info() {
  sudo bash -c "LOG_DIR=${LOG_DIR:-/tmp/bashlib_log} ; $(declare -f __log); __log info \"$*\""
}
