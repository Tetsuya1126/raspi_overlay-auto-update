#!/bin/bash
# =================================================
# Platform detector (PC / Raspberry Pi)
# =================================================
#
# return convention:
#   0 true
#   1 false
#

# ---------------------------------------
# Raspberry Pi detection
# ---------------------------------------
is_raspberry_pi() {
    local model=""

    if [[ -r /proc/device-tree/model ]]; then
        model="$(tr -d '\0' </proc/device-tree/model)"
    elif [[ -r /sys/firmware/devicetree/base/model ]]; then
        model="$(tr -d '\0' </sys/firmware/devicetree/base/model)"
    fi

    [[ "$model" =~ Raspberry\ Pi ]] && return 0
    return 1
}

# ---------------------------------------
# Generic PC detection
# ---------------------------------------
is_pc() {
    is_raspberry_pi && return 1
    return 0
}

# ---------------------------------------
# platform name
# ---------------------------------------
platform_name() {
    if is_raspberry_pi; then
        echo "raspi"
    else
        echo "pc"
    fi
}
