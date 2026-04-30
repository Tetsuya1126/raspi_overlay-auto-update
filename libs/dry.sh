#!/bin/bash
# bashlib/core/dry.sh
# DRY-RUN フラグ管理モジュール

dry_init() {
  DRY=false

  for arg in "$@"; do
    case "$arg" in
      --dry|-n|--dry-run)
        DRY=true
        ;;
    esac
  done

  if [[ "$DRY" == true ]]; then
    log_info "[DRY MODE ENABLED] コマンド実行は行わず、ログのみ出力します"
    export DRY=true
  fi
}

dry_eval() {
  if [[ "${DRY:-false}" == true ]]; then
    log_info "[DRY] $*"
    return 0
  fi

  eval "$*"
}

_dry_eval() {
  if [[ "${DRY:-false}" == true ]]; then
    log_info "[DRY] $(printf '%q ' "$@")"
    return 0
  fi

  "$@"
}

dry_run_mode() {
  # ==== DRY MODE 判定 ====
  # 既に DRY が export 済みなら尊重する
  if [[ -z "${DRY:-}" ]]; then
    dry_init "$@"      # ← DRY が未定義のときのみ引数から判定
  else
    log_info "[DRY MODE inherited] DRY_MODE=$DRY"
  fi
}
