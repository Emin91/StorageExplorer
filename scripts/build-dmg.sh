#!/bin/bash
#
#  build-dmg.sh
#  ReactNativeStorageExplorer
#
#  Created by Emin Zeynalov on 31.03.26.
#
#  Builds a Release version of Storage Explorer and packs it into a styled DMG:
#  custom background with install hints, app on the left, Applications shortcut on the right.
#
#  Usage: ./scripts/build-dmg.sh
#  Result: build/StorageExplorer-<version>.dmg
#
#  The first run asks to allow Terminal to control Finder (used to lay out the DMG window).
#

set -euo pipefail

cd "$(dirname "$0")/.."

PROJECT="ReactNativeStorageExplorer.xcodeproj"
TARGET="ReactNativeStorageExplorer"
APP_NAME="Storage Explorer"
BUILD_DIR="$PWD/build"
STAGING_DIR="$BUILD_DIR/dmg"
ASSETS_DIR="$PWD/scripts/dmg"

# DMG window layout, in points; must match the background images (660×400).
WINDOW_WIDTH=660
WINDOW_HEIGHT=400
ICON_SIZE=128
APP_ICON_POSITION="170, 190"
APPLICATIONS_ICON_POSITION="490, 190"

VERSION=$(xcodebuild -project "$PROJECT" -target "$TARGET" -configuration Release -showBuildSettings 2>/dev/null \
    | awk -F' = ' '/ MARKETING_VERSION = / { print $2; exit }')
DMG_PATH="$BUILD_DIR/StorageExplorer-$VERSION.dmg"
RW_DMG_PATH="$BUILD_DIR/StorageExplorer-rw.dmg"

echo "▸ Building $APP_NAME $VERSION (Release, Apple Silicon + Intel)…"
rm -rf "$BUILD_DIR"
xcodebuild -project "$PROJECT" -target "$TARGET" -configuration Release \
    SYMROOT="$BUILD_DIR" ONLY_ACTIVE_ARCH=NO \
    -quiet build

BUILT_APP="$BUILD_DIR/Release/$TARGET.app"
codesign --verify --deep --strict "$BUILT_APP"

echo "▸ Preparing DMG contents…"
mkdir -p "$STAGING_DIR/.background"
# The bundle is renamed for users; the folder name is not part of the code signature.
cp -R "$BUILT_APP" "$STAGING_DIR/$APP_NAME.app"
ln -s /Applications "$STAGING_DIR/Applications"
# One TIFF with both resolutions, so the background is sharp on Retina displays.
tiffutil -cathidpicheck "$ASSETS_DIR/background.png" "$ASSETS_DIR/background@2x.png" \
    -out "$STAGING_DIR/.background/background.tiff" 2>/dev/null
# Volume icon: the app icon compiled by Xcode.
cp "$BUILT_APP/Contents/Resources/AppIcon.icns" "$STAGING_DIR/.VolumeIcon.icns" 2>/dev/null || true

echo "▸ Styling DMG window…"
# A volume with the same name (e.g. a previously opened DMG) would make the new one mount as "… 1".
for volume in "/Volumes/$APP_NAME"*; do
    [ -d "$volume" ] && hdiutil detach "$volume" -force -quiet || true
done

hdiutil create -volname "$APP_NAME" -srcfolder "$STAGING_DIR" -ov -format UDRW "$RW_DMG_PATH" >/dev/null
MOUNT_POINT=$(hdiutil attach -readwrite -noverify -noautoopen "$RW_DMG_PATH" | awk -F'\t' '/\/Volumes\// { print $NF }')
VOLUME_NAME=$(basename "$MOUNT_POINT")
# Detach the image even if a later step fails.
trap 'hdiutil detach "$MOUNT_POINT" -force -quiet 2>/dev/null || true' EXIT
SetFile -a C "$MOUNT_POINT" 2>/dev/null || true
# Give Finder a moment to register the new volume.
sleep 2

osascript <<APPLESCRIPT
tell application "Finder"
    tell disk "$VOLUME_NAME"
        open
        set current view of container window to icon view
        set toolbar visible of container window to false
        set statusbar visible of container window to false
        -- Bounds include the title bar.
        set the bounds of container window to {200, 120, 200 + $WINDOW_WIDTH, 120 + $WINDOW_HEIGHT + 28}
        set viewOptions to the icon view options of container window
        set arrangement of viewOptions to not arranged
        set icon size of viewOptions to $ICON_SIZE
        set text size of viewOptions to 13
        set background picture of viewOptions to file ".background:background.tiff"
        set position of item "$APP_NAME.app" of container window to {$APP_ICON_POSITION}
        set position of item "Applications" of container window to {$APPLICATIONS_ICON_POSITION}
        update without registering applications
        delay 1
        close
    end tell
end tell
APPLESCRIPT

sync
hdiutil detach "$MOUNT_POINT" -quiet
trap - EXIT

echo "▸ Compressing DMG…"
hdiutil convert "$RW_DMG_PATH" -format UDZO -imagekey zlib-level=9 -o "$DMG_PATH" >/dev/null
rm -rf "$RW_DMG_PATH" "$STAGING_DIR"

echo "✓ $DMG_PATH"
