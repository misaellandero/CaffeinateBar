# CaffeinateBar ☕

A minimal macOS menu bar app that keeps your Mac awake using `caffeinate`, with full control over all assertion flags.

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

## Project Structure

```
CaffeinateBar/
├── project.yml                  # xcodegen spec
├── CaffeinateBar.xcodeproj/
└── CaffeinateBar/
    ├── CaffeinateBarApp.swift   # @main + MenuBarExtra scene
    ├── CaffeinateManager.swift  # Process wrapper, flag state, UserDefaults persistence
    ├── MenuBarView.swift        # SwiftUI popover — assertions, timeout, preview, toggle
    └── Assets.xcassets/
```

## Regenerate Xcode project

```bash
xcodegen generate
```
