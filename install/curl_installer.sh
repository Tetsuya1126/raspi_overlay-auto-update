#!/bin/bash
set -euo pipefail

REPO_URL="https://github.com/Tetsuya1126/raspi_overlay-auto-update.git"
BRANCH="v2.0.0-rc"

TMP_DIR="$(mktemp -d)"

cleanup() {
    rm -rf "$TMP_DIR"
}
trap cleanup EXIT

echo "🚀 Downloading installer..."

git clone --depth=1 --branch "$BRANCH" \
    "$REPO_URL" "$TMP_DIR/repo"

cd "$TMP_DIR/repo/install"

bash ./install.sh
