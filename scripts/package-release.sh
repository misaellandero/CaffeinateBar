#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PROJECT="$ROOT_DIR/CaffeinateBar.xcodeproj"
SCHEME="CaffeinateBar"
CONFIGURATION="${CONFIGURATION:-Release}"
DERIVED_DATA="$ROOT_DIR/build/DerivedData"
ARCHIVE_PATH="$ROOT_DIR/build/$SCHEME.xcarchive"
DIST_DIR="$ROOT_DIR/dist"

rm -rf "$DERIVED_DATA" "$ARCHIVE_PATH" "$DIST_DIR"
mkdir -p "$DIST_DIR"

SETTINGS="$(xcodebuild -project "$PROJECT" -scheme "$SCHEME" -configuration "$CONFIGURATION" -showBuildSettings)"
VERSION="$(printf '%s\n' "$SETTINGS" | awk -F'= ' '/MARKETING_VERSION/ {print $2; exit}')"
BUILD_NUMBER="$(printf '%s\n' "$SETTINGS" | awk -F'= ' '/CURRENT_PROJECT_VERSION/ {print $2; exit}')"

xcodebuild \
  -project "$PROJECT" \
  -scheme "$SCHEME" \
  -configuration "$CONFIGURATION" \
  -archivePath "$ARCHIVE_PATH" \
  -derivedDataPath "$DERIVED_DATA" \
  clean archive \
  CODE_SIGN_STYLE=Manual \
  CODE_SIGN_IDENTITY="-" \
  CODE_SIGN_ENTITLEMENTS="" \
  DEVELOPMENT_TEAM="" \
  PROVISIONING_PROFILE_SPECIFIER=""

APP_PATH="$ARCHIVE_PATH/Products/Applications/$SCHEME.app"
VERSIONED_ZIP="$DIST_DIR/$SCHEME-$VERSION-$BUILD_NUMBER-macOS.zip"
LATEST_ZIP="$DIST_DIR/$SCHEME-macOS.zip"

ditto -c -k --keepParent "$APP_PATH" "$VERSIONED_ZIP"
cp "$VERSIONED_ZIP" "$LATEST_ZIP"

(
  cd "$DIST_DIR"
  shasum -a 256 "$(basename "$VERSIONED_ZIP")" "$(basename "$LATEST_ZIP")" > SHA256SUMS.txt
)

printf 'Created release artifacts:\n'
printf '  %s\n' "$VERSIONED_ZIP"
printf '  %s\n' "$LATEST_ZIP"
printf '  %s\n' "$DIST_DIR/SHA256SUMS.txt"
