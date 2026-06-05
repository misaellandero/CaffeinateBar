# CaffeinateBar ☕

A minimal macOS menu bar app that keeps your display awake using `caffeinate -d`.

## Features

- **Menu bar icon** — `cup.and.saucer.fill` when active, `cup.and.saucer` when idle
- **One-click toggle** — enable or disable with ⌘K
- **Elapsed timer** — shows how long the display has been kept awake
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

After building, the app lives in `~/Library/Developer/Xcode/DerivedData/.../CaffeinateBar.app`.

## Project Structure

```
CaffeinateBar/
├── project.yml                  # xcodegen spec
├── CaffeinateBar.xcodeproj/
└── CaffeinateBar/
    ├── CaffeinateBarApp.swift   # @main + MenuBarExtra scene
    ├── CaffeinateManager.swift  # Process wrapper + elapsed timer
    ├── MenuBarView.swift        # SwiftUI popover UI
    └── Assets.xcassets/
```

## Regenerate Xcode project

If you change `project.yml`, regenerate with:

```bash
xcodegen generate
```
