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
mkdir -p "$STAGING/.background" "$DIST_DIR"

cp -R "$APP_PATH" "$STAGING/"
ln -s /Applications "$STAGING/Applications"
cp "$BACKGROUND" "$STAGING/.background/background.png"

hdiutil create \
  -volname "$VOLNAME" \
  -srcfolder "$STAGING" \
  -ov \
  -format UDRW \
  "$RW_DMG" >/dev/null

for existing_mount in /Volumes/"$VOLNAME"*; do
  if [[ -d "$existing_mount" ]]; then
    hdiutil detach "$existing_mount" -quiet || true
  fi
done

hdiutil attach "$RW_DMG" -readwrite -noverify -noautoopen >/dev/null
MOUNT_POINT="/Volumes/$VOLNAME"

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
  set bgFile to POSIX file "$MOUNT_POINT/.background/background.png" as alias
  tell disk "$VOLNAME"
    open
    delay 1
    set current view of container window to icon view
    set toolbar visible of container window to false
    set statusbar visible of container window to false
    set bounds of container window to {120, 120, 1020, 720}
    set theViewOptions to the icon view options of container window
    tell theViewOptions
      set arrangement to not arranged
      set icon size to 128
    end tell
    set background picture of theViewOptions to bgFile
    set position of item "$SCHEME.app" of container window to {286, 343}
    set position of item "Applications" of container window to {616, 343}
    close
    open
    update without registering applications
    delay 1
  end tell
end tell
APPLESCRIPT

sync
if [[ ! -f "$MOUNT_POINT/.DS_Store" ]]; then
  echo "Finder did not write DMG layout metadata." >&2
  exit 1
fi
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
  {
    [[ -f "$SCHEME-1.0-1-macOS.zip" ]] && shasum -a 256 "$SCHEME-1.0-1-macOS.zip"
    [[ -f "$SCHEME-macOS.zip" ]] && shasum -a 256 "$SCHEME-macOS.zip"
    shasum -a 256 "$(basename "$FINAL_DMG")" "$(basename "$LATEST_DMG")"
  } > SHA256SUMS.txt
)

printf 'Created DMG artifacts:\n'
printf '  %s\n' "$FINAL_DMG"
printf '  %s\n' "$LATEST_DMG"
