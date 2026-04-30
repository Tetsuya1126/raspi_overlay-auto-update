#!/bin/bash
# =================================================
# LED control (Raspberry Pi only, PC-safe)
# =================================================
#
# Design:
# - no-op on non-Raspberry Pi
# - never exit
#

# requires:
#   detect_platform.sh

# ---------------------------------------
# helpers
# ---------------------------------------

__led_available() {
    is_raspberry_pi || return 1
    [[ -d "$LED_RED_DEVICE" || -d "$LED_GREEN_DEVICE" ]]
}

__led_write() {
    local dev="$1"
    local value="$2"
    [[ -w "$dev/brightness" ]] || return 0
    echo "$value" >"$dev/brightness" 2>/dev/null || true
}

# ---------------------------------------
# public API
# ---------------------------------------

led_init() {
    __led_available || return 0

    for dev in "$LED_RED_DEVICE" "$LED_GREEN_DEVICE"; do
        [[ -d "$dev" ]] || continue
        echo "none" >"$dev/trigger" 2>/dev/null || true
    done
}

led_on() {
    local color="$1"
    __led_available || return 0

    case "$color" in
        red)
            __led_write "$LED_RED_DEVICE" 1
            ;;
        green)
            __led_write "$LED_GREEN_DEVICE" 1
            ;;
    esac
}

led_off() {
    local color="$1"
    __led_available || return 0

    case "$color" in
        red)
            __led_write "$LED_RED_DEVICE" 0
            ;;
        green)
            __led_write "$LED_GREEN_DEVICE" 0
            ;;
    esac
}

led_flash() {
    local color="$1"
    local count="${2:-3}"
    local interval_ms="${3:-$LED_FLASH_INTERVAL_MS}"

    __led_available || return 0

    local i
    for ((i=0; i<count; i++)); do
        led_on "$color"
        sleep "$(awk "BEGIN {print $interval_ms/1000}")"
        led_off "$color"
        sleep "$(awk "BEGIN {print $interval_ms/1000}")"
    done

   # 完了時はDefault
    led_restore
}

# Utility: sleep in ms without awk (ShellCheck-safe)
sleep_ms() {
    local ms=$1
    local sec=$(( ms / 1000 ))
    local rem=$(( ms % 1000 ))

    if (( sec > 0 )); then
        sleep "$sec"
    fi

    if (( rem > 0 )); then
        sleep "0.$(printf "%03d" "$rem")"
    fi
}

led_flash_for() {
    local color="$1"
    local duration_sec="$2"                 # 実行時間（秒）
    local interval_ms="${3:-$LED_FLASH_INTERVAL_MS}"
    local end_ts

    __led_available || return 0

    # 開始時刻と終了時刻
    end_ts=$(( $(date +%s) + duration_sec ))

    # trap（安全に LED OFF）
    trap 'led_restore ; exit 0' SIGINT SIGTERM

    while : ; do
        # 現在時刻が終了時刻を超えたら停止
        if (( $(date +%s) >= end_ts )); then
            break
        fi

        led_on "$color"
        sleep_ms "$interval_ms"
        led_off "$color"
        sleep_ms "$interval_ms"
    done

    # 完了時はDefault
    led_restore
}

led_flash_infinite() {
    # 🔁 停止方法
    # 無限ループ関数は実行すると止まりませんので、停止は Ctrl + C、またはスクリプト外から kill が必要です。
    # 例: pkill -f "led_flash_infinite"
    #
    # 🧠 追加Tip — systemd で止められる設計にするなら
    # もし systemd サービスとして動かす場合は Type=simple にし、
    # while true で動かし続け、trapでサービス停止時にクリーンアップします
    
    local color="$1"
    local interval_ms="${2:-$LED_FLASH_INTERVAL_MS}"

    __led_available || return 0

    trap 'led_off "$color"; exit 0' SIGINT SIGTERM

    while true; do
        led_on "$color"
        sleep "$(awk "BEGIN {print $interval_ms/1000}")"
        led_off "$color"
        sleep "$(awk "BEGIN {print $interval_ms/1000}")"
    done

}


led_restore() {
    __led_available || return 0

    [[ -w "$LED_GREEN_DEVICE/trigger" ]] && echo "mmc0" >"$LED_GREEN_DEVICE/trigger"
    [[ -w "$LED_RED_DEVICE/trigger"   ]] && echo "default-on" >"$LED_RED_DEVICE/trigger"
}


# ---------------------------------------
# debug / info
# ---------------------------------------
led_list_triggers() {
    local target="$1"
    local dev

    __led_available || return 0

    case "$target" in
        red)
            dev="$LED_RED_DEVICE"
            ;;
        green)
            dev="$LED_GREEN_DEVICE"
            ;;
        *)
            dev="/sys/class/leds/$target"
            ;;
    esac

    [[ -r "$dev/trigger" ]] || return 0

    echo "LED: $(basename "$dev")"
    echo "Available triggers:"

    # trigger ファイルは
    # none mmc0 [heartbeat]
    # のような形式
    # shellcheck disable=SC2013
    for t in $(cat "$dev/trigger"); do
        if [[ "$t" =~ ^\[.*\]$ ]]; then
            echo "  * ${t#[}"
            echo "    ${t%]}"
        else
            echo "    $t"
        fi
    done
}
