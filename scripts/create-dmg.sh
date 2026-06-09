#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SCHEME="CaffeinateBar"
VERSION="${VERSION:-1.0}"
VOLNAME="$SCHEME $VERSION"
BUILD_DIR="$ROOT_DIR/build/dmg"
DIST_DIR="$ROOT_DIR/dist"
APP_PATH="$ROOT_DIR/build/$SCHEME.xcarchive/Products/Applications/$SCHEME.app"
BACKGROUND="$ROOT_DIR/assets/dmg-background.png"
STAGING="$BUILD_DIR/staging"
MOUNT_POINT="$BUILD_DIR/mount"
RW_DMG="$BUILD_DIR/$SCHEME-rw.dmg"
FINAL_DMG="$DIST_DIR/$SCHEME-$VERSION-macOS.dmg"
LATEST_DMG="$DIST_DIR/$SCHEME-macOS.dmg"

if [[ ! -d "$APP_PATH" ]]; then
  "$ROOT_DIR/scripts/package-release.sh"
fi

if [[ ! -f "$BACKGROUND" ]]; then
  echo "Missing DMG background: $BACKGROUND" >&2
  exit 1
fi

rm -rf "$BUILD_DIR" "$FINAL_DMG" "$LATEST_DMG"
mkdir -p "$STAGING/.background" "$MOUNT_POINT" "$DIST_DIR"

cp -R "$APP_PATH" "$STAGING/"
ln -s /Applications "$STAGING/Applications"
cp "$BACKGROUND" "$STAGING/.background/background.png"

hdiutil create \
  -volname "$VOLNAME" \
  -srcfolder "$STAGING" \
  -ov \
  -format UDRW \
  "$RW_DMG" >/dev/null

hdiutil attach "$RW_DMG" -readwrite -noverify -noautoopen -mountpoint "$MOUNT_POINT" >/dev/null

cleanup() {
  if [[ -n "${MOUNT_POINT:-}" && -d "$MOUNT_POINT" ]]; then
    hdiutil detach "$MOUNT_POINT" -quiet || true
  fi
}
trap cleanup EXIT

mkdir -p "$MOUNT_POINT/.background"
cp "$BACKGROUND" "$MOUNT_POINT/.background/background.png"

osascript <<APPLESCRIPT
tell application "Finder"
  set dmgFolder to POSIX file "$MOUNT_POINT" as alias
  set bgFile to POSIX file "$MOUNT_POINT/.background/background.png" as alias
  open dmgFolder
  delay 1
  set current view of container window of dmgFolder to icon view
  set toolbar visible of container window of dmgFolder to false
  set statusbar visible of container window of dmgFolder to false
  set bounds of container window of dmgFolder to {120, 120, 920, 620}
  set theViewOptions to the icon view options of container window of dmgFolder
  tell theViewOptions
    set arrangement to not arranged
    set icon size to 96
  end tell
  set background picture of theViewOptions to bgFile
  set position of item "$SCHEME.app" of dmgFolder to {205, 255}
  set position of item "Applications" of dmgFolder to {595, 255}
  close container window of dmgFolder
  open dmgFolder
  update dmgFolder without registering applications
  delay 1
end tell
APPLESCRIPT

sync
hdiutil detach "$MOUNT_POINT" -quiet
trap - EXIT

for attempt in 1 2 3 4 5; do
  if hdiutil convert "$RW_DMG" -format UDZO -imagekey zlib-level=9 -o "$FINAL_DMG" >/dev/null; then
    break
  fi
  if [[ "$attempt" == "5" ]]; then
    echo "Failed to convert DMG after $attempt attempts." >&2
    exit 1
  fi
  sleep 2
done
cp "$FINAL_DMG" "$LATEST_DMG"

(
  cd "$DIST_DIR"
  shasum -a 256 "$(basename "$FINAL_DMG")" "$(basename "$LATEST_DMG")" >> SHA256SUMS.txt
)

printf 'Created DMG artifacts:\n'
printf '  %s\n' "$FINAL_DMG"
printf '  %s\n' "$LATEST_DMG"
