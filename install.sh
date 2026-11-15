#!/bin/bash
#
#  install.sh
#  ReactNativeStorageExplorer
#
#  Created by Emin Zeynalov on 31.03.26.
#
#  Installs (or updates) the latest Storage Explorer release from GitHub:
#
#      curl -fsSL https://raw.githubusercontent.com/Emin91/StorageExplorer/main/install.sh | bash
#
#  Files downloaded with curl get no "downloaded from the internet" mark,
#  so macOS doesn't show the "can't verify the developer" warning.
#

set -euo pipefail

REPO="Emin91/StorageExplorer"
APP_NAME="Storage Explorer"
INSTALL_DIR="/Applications"
APP_PATH="$INSTALL_DIR/$APP_NAME.app"

TEMP_DIR=$(mktemp -d)
MOUNT_POINT=""

cleanup() {
    [ -n "$MOUNT_POINT" ] && hdiutil detach "$MOUNT_POINT" -quiet 2>/dev/null || true
    rm -rf "$TEMP_DIR"
}
trap cleanup EXIT

fail() {
    echo "✗ $1" >&2
    exit 1
}

[ "$(uname)" = "Darwin" ] || fail "Storage Explorer works only on macOS."

echo "▸ Looking up the latest release…"
DMG_URL=$(curl -fsSL "https://api.github.com/repos/$REPO/releases/latest" \
    | grep -o '"browser_download_url": *"[^"]*\.dmg"' \
    | head -n 1 \
    | sed -E 's/.*"(https[^"]+)"/\1/') || true
[ -n "$DMG_URL" ] || fail "No DMG found in the latest release of $REPO."

echo "▸ Downloading $(basename "$DMG_URL")…"
curl -fL --progress-bar "$DMG_URL" -o "$TEMP_DIR/StorageExplorer.dmg"

echo "▸ Installing to ${INSTALL_DIR}…"
MOUNT_POINT=$(hdiutil attach -nobrowse -readonly -noautoopen "$TEMP_DIR/StorageExplorer.dmg" \
    | awk -F'\t' '/\/Volumes\// { print $NF }')
[ -d "$MOUNT_POINT/$APP_NAME.app" ] || fail "The DMG doesn't contain $APP_NAME.app."

# Quit a running copy so it can be replaced.
osascript -e "quit app \"$APP_NAME\"" 2>/dev/null || true

# /Applications is writable for admin users; otherwise ask for the password.
SUDO=""
[ -w "$INSTALL_DIR" ] || SUDO="sudo"
$SUDO rm -rf "$APP_PATH"
$SUDO cp -R "$MOUNT_POINT/$APP_NAME.app" "$INSTALL_DIR/"
$SUDO xattr -dr com.apple.quarantine "$APP_PATH" 2>/dev/null || true

echo "✓ Installed $APP_PATH"
echo "  On first launch, allow Accessibility when asked: the panel uses it to follow iOS Simulator."
open "$APP_PATH"
