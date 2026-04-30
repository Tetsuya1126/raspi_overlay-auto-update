#!/bin/bash
# =================================================
# Lock module (overlay-safe)
# =================================================

# require:
#   constants/constants.sh
#   core/error.sh
#   hardware/detect_overlay.sh

# =================================================
# Lock paths (overlay-safe)
# =================================================
if is_overlay_enabled; then
    # overlayroot 環境（永続 RW 領域）
    BASHLIB_LOCK_PERSIST_DIR="/media/root-rw/locks"
else
    # 通常環境
    BASHLIB_LOCK_PERSIST_DIR="/var/lib/bashlib/locks"
fi

BASHLIB_LOCK_RUNTIME_DIR="/run/bashlib/locks"

mkdir -p "$BASHLIB_LOCK_PERSIST_DIR" "$BASHLIB_LOCK_RUNTIME_DIR"

# ---------------------------------------
# internal: held lock fds
# ---------------------------------------
declare -ag __BASHLIB_LOCK_FDS=()

# ---------------------------------------
# init
# ---------------------------------------
lock_init() {
    [[ -d "$BASHLIB_LOCK_PERSIST_DIR" ]] \
        || die "lock dir not found: $BASHLIB_LOCK_PERSIST_DIR"

    [[ -d "$BASHLIB_LOCK_RUNTIME_DIR" ]] \
        || die "lock dir not found: $BASHLIB_LOCK_RUNTIME_DIR"
}

# ---------------------------------------
# acquire lock
# ---------------------------------------
lock_acquire() {
    local name="$1"
    local lockfile

    [[ -z "$name" ]] && die "lock_acquire: name required"

    if is_overlay_enabled; then
        lockfile="$BASHLIB_LOCK_RUNTIME_DIR/${name}.lock"
    else
        lockfile="$BASHLIB_LOCK_PERSIST_DIR/${name}.lock"
    fi

    # open fd 200
    exec 200>"$lockfile" || {
        die "cannot create lockfile (permission?): $lockfile"
    }

    # try lock
    if ! flock -n 200; then
        exec 200>&-
        return 1
    fi

    __BASHLIB_LOCK_FDS+=(200)
    return 0
}

# ---------------------------------------
# release all locks
# ---------------------------------------
lock_release() {
    local fd
    for fd in "${__BASHLIB_LOCK_FDS[@]}"; do
        exec {fd}>&- 2>/dev/null || true
    done
    __BASHLIB_LOCK_FDS=()
}
