#!/bin/bash

ensure_yq() {
  if command -v yq >/dev/null 2>&1; then
    return 0
  fi
  
  echo "[INFO] yq not found. Installing yq..."
  ARCH=$(uname -m)
  case "$ARCH" in
    x86_64)   YQ_BIN="yq_linux_amd64" ;;
    aarch64)  YQ_BIN="yq_linux_arm64" ;;
    armv7l)   YQ_BIN="yq_linux_arm" ;;  # Raspberry Pi 32bit
    *)        echo "[ERROR] Unsupported arch: $ARCH" ; return 1 ;;
  esac

  wget -q "https://github.com/mikefarah/yq/releases/latest/download/${YQ_BIN}" \
   -O /usr/local/bin/yq || return 1
  chmod +x /usr/local/bin/yq
}

# 便利 wrapper 関数: yq_get path file
yq_get() {
  local SEARCH_PATH="$1"
  local FILE="$2"
  if [ "$YQ_MAJOR" -ge 4 ]; then
    # v4系
    yq ".$SEARCH_PATH" "$FILE"
  else
    # v3系
    yq -r ".$SEARCH_PATH" "$FILE"
  fi
}


# --- yq バージョン判定 ---
if ! command -v yq >/dev/null 2>&1; then
  ensure_yq
fi

YQ_VERSION=$(yq --version 2>/dev/null | grep -oE '[0-9]+\.[0-9]+')
YQ_MAJOR=$(echo "$YQ_VERSION" | cut -d. -f1)

