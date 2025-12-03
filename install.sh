#!/usr/bin/env bash
set -euo pipefail

echo "=== OverlayFS Safe Auto Update Installer ==="

# root check
[ "$EUID" -ne 0 ] && {
  echo "Run as root"
  exit 1
}

# check files
for f in overlay-auto-update.sh overlay-auto-update.service overlay-auto-update.timer; do
  [ -f "$f" ] || { echo "Missing $f"; exit 1; }
done

### install script ###
install -m 755 overlay-auto-update.sh /usr/local/sbin/

### install service ###
install -m 644 overlay-auto-update.service /etc/systemd/system/
install -m 644 overlay-auto-update.timer   /etc/systemd/system/

### reload systemd
systemctl daemon-reload

### enable timer
systemctl enable --now overlay-auto-update.timer

echo "=== Install complete ==="
systemctl list-timers --all | grep overlay-auto-update || true
