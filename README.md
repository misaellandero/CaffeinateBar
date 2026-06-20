# CaffeinateBar

A minimal macOS menu bar app that keeps your Mac awake using `caffeinate`, with full control over all assertion flags.

## Download

Download the latest release:

[Download CaffeinateBar on the App Store](https://apple.co/4oGcw7D)

Install:

1. Open the App Store link.
2. Download CaffeinateBar.
3. Launch it from your Applications folder.

GitHub release builds are also available for manual installation:

[CaffeinateBar-macOS.dmg](https://github.com/misaellandero/CaffeinateBar/releases/latest/download/CaffeinateBar-macOS.dmg)

## Features

- **Menu bar icon** — `cup.and.saucer.fill` (active) / `cup.and.saucer` (idle) with a live status dot
- **All caffeinate flags exposed** via toggle switches:
  | Flag | Effect |
  |------|--------|
  | `-d` | Prevent **display** from sleeping |
  | `-i` | Prevent **idle** sleep |
  | `-m` | Prevent **disk** idle sleep |
  | `-s` | Prevent **system** sleep *(AC power only)* |
- **Timeout presets** (`-t`) — No timeout, 15 min, 30 min, 1 h, 2 h, 4 h, 8 h
- **Live command preview** — shows the exact `caffeinate …` command being run
- **Elapsed timer** — shows how long caffeinate has been active
- **Persistent settings** — choices are saved to UserDefaults across launches
- **No Dock icon** — lives entirely in the menu bar (`LSUIElement = YES`)

## Requirements

- macOS 13.0+
- Xcode 15+

## Build & Run

```bash
# Open in Xcode
open CaffeinateBar.xcodeproj

# Or build from CLI
xcodebuild -project CaffeinateBar.xcodeproj -scheme CaffeinateBar -configuration Release build
```

## Create a GitHub release

```bash
scripts/package-release.sh
scripts/create-dmg.sh
git tag v1.0.0
git push origin main --tags
gh release create v1.0.0 dist/CaffeinateBar-macOS.dmg dist/CaffeinateBar-*-macOS.dmg dist/CaffeinateBar-macOS.zip dist/CaffeinateBar-*-macOS.zip dist/SHA256SUMS.txt --title "CaffeinateBar v1.0.0"
```

The release upload includes:

- `CaffeinateBar-macOS.dmg`
- `CaffeinateBar-<version>-macOS.dmg`
- `CaffeinateBar-macOS.zip`
- `CaffeinateBar-<version>-<build>-macOS.zip`
- `SHA256SUMS.txt`

## Project Structure

```
CaffeinateBar/
├── project.yml                  # xcodegen spec
├── scripts/package-release.sh    # builds release zip artifacts
├── scripts/create-dmg.sh         # builds drag-to-Applications DMG artifacts
├── assets/dmg-background.png     # DMG Finder background
├── CaffeinateBar.xcodeproj/
└── CaffeinateBar/
    ├── CaffeinateBar.entitlements
    ├── CaffeinateBarApp.swift   # @main + MenuBarExtra scene
    ├── CaffeinateManager.swift  # Process wrapper, flag state, UserDefaults persistence
    ├── MenuBarView.swift        # SwiftUI popover — assertions, timeout, preview, toggle
    └── Assets.xcassets/
```

## Regenerate Xcode project

```bash
xcodegen generate
```
