#!/bin/bash
# =================================================
# Overlay filesystem detector
# =================================================

# -------------------------------------------------
# runtime check:
#   true  -> / is mounted as overlayfs
#   false -> otherwise
# -------------------------------------------------
overlay_is_enabled() {
    # findmnt が使える環境を最優先
    if command -v findmnt >/dev/null 2>&1; then
        findmnt -n -o FSTYPE / 2>/dev/null | grep -q '^overlay$'
        return $?
    fi

    # fallback (very old systems)
    mount | grep -E ' on / ' | grep -q ' type overlay '
}

# -------------------------------------------------
# config check:
#   true  -> overlayroot is configured (fstab)
#   false -> not configured
# -------------------------------------------------
is_overlay_configured() {
    # overlayroot の典型的 signature
    grep -qE '^/media/root-ro/.*overlay' /etc/fstab 2>/dev/null
}

# -------------------------------------------------
# backward compatible API
#   true if runtime OR configured
# -------------------------------------------------
is_overlay_enabled() {
    overlay_is_enabled && return 0
    is_overlay_configured && return 0
    return 1
}

# -------------------------------------------------
# check if overlayfs *can be enabled* (kernel support)
# true -> overlayfs available in kernel
# false -> unsupported
# -------------------------------------------------
overlay_is_configurable() {
    # /proc/filesystems に overlay が存在するか
    if grep -qw overlay /proc/filesystems 2>/dev/null; then
        return 0
    fi

    # or modprobe でロード可能か（組み込み型なら modprobe 不要）
    if command -v modprobe >/dev/null 2>&1; then
        modprobe -n overlay >/dev/null 2>&1 && return 0
    fi

    return 1
}

# true if:
#   - overlay is already active (runtime)
#   - overlay is configured in fstab
#   - overlayfs is supported by kernel (can be enabled)
is_overlay_possible() {
    overlay_is_enabled && return 0
    is_overlay_configured && return 0
    overlay_is_configurable && return 0
    return 1
}
