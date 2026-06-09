import AppKit
import SwiftUI
import Combine

class AppDelegate: NSObject, NSApplicationDelegate {

    let manager = CaffeinateManager()
    private var statusItem: NSStatusItem!
    private var popover: NSPopover!
    private var hotkeyManager: HotkeyManager?
    private var cancellables = Set<AnyCancellable>()
    private var suppressNextOpen = false

    func applicationDidFinishLaunching(_ notification: Notification) {
        setupStatusItem()
        setupPopover()
        setupObservers()
        if manager.activateOnLaunch { manager.enable() }
    }

    // MARK: - Status Item

    private func setupStatusItem() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        updateIcon()
        guard let button = statusItem.button else { return }
        button.target = self
        button.action = #selector(handleClick(_:))
        button.sendAction(on: [.leftMouseUp, .rightMouseUp])
    }

    // MARK: - Icon  (always filled cup, green = active, dimmed = inactive)

    func updateIcon() {
        guard let button = statusItem.button,
              let base = NSImage(systemSymbolName: "cup.and.saucer.fill",
                                 accessibilityDescription: nil) else { return }
        if manager.colorIcon {
            // Explicit color: green when active, gray when inactive
            let color: NSColor = manager.isActive ? .systemGreen : .tertiaryLabelColor
            if let img = base.withSymbolConfiguration(
                NSImage.SymbolConfiguration(paletteColors: [color])) {
                img.isTemplate = false
                button.image = img
            }
        } else {
            // System template: macOS auto-adapts to dark/light mode (standard B&W)
            let symbol = manager.isActive ? "cup.and.saucer.fill" : "cup.and.saucer"
            if let img = NSImage(systemSymbolName: symbol, accessibilityDescription: nil) {
                img.isTemplate = true
                button.image = img
            }
        }
    }

    // MARK: - Popover

    private func setupPopover() {
        let hosting = NSHostingController(
            rootView: MenuBarView().environmentObject(manager)
        )

        popover = NSPopover()
        popover.behavior  = .transient
        popover.delegate  = self
        popover.contentViewController = hosting
    }

    @objc private func handleClick(_ sender: NSStatusBarButton) {
        guard let event = NSApp.currentEvent else { return }

        // Right-click → quick context menu
        if event.type == .rightMouseUp {
            showContextMenu(); return
        }

        // Left-click + toggle mode → just toggle
        if manager.leftClickToToggle {
            if popover.isShown { popover.performClose(nil) }
            manager.toggle(); return
        }

        togglePopover()
    }

    private func togglePopover() {
        guard let button = statusItem.button else { return }
        if popover.isShown {
            popover.performClose(nil)
        } else if !suppressNextOpen {
            popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
            NSApp.activate(ignoringOtherApps: true)
        }
    }

    private func showContextMenu() {
        let menu = NSMenu()
        menu.autoenablesItems = false
        let t = NSMenuItem(title: NSLocalizedString("Disable Caffeinate", comment: "Menu item to disable caffeinate"),
                           action: #selector(toggleCaffeinate), keyEquivalent: "k")
        if manager.isActive {
            t.title = NSLocalizedString("Disable Caffeinate", comment: "Menu item to disable caffeinate")
        } else {
            t.title = NSLocalizedString("Enable Caffeinate", comment: "Menu item to enable caffeinate")
        }
        t.keyEquivalentModifierMask = .command; t.target = self
        menu.addItem(t)
        menu.addItem(.separator())
        menu.addItem(NSMenuItem(title: NSLocalizedString("Quit CaffeinateBar", comment: "Menu item to quit the application"),
                                action: #selector(NSApplication.terminate(_:)),
                                keyEquivalent: "q"))
        statusItem.menu = menu
        statusItem.button?.performClick(nil)
        DispatchQueue.main.async { self.statusItem.menu = nil }
    }

    @objc private func toggleCaffeinate() { manager.toggle() }

    // MARK: - Observers

    private func setupObservers() {
        Publishers.MergeMany(
            manager.$isActive.map { _ in () },
            manager.$colorIcon.map { _ in () }
        )
        .receive(on: DispatchQueue.main)
        .sink { [weak self] in self?.updateIcon() }
        .store(in: &cancellables)

        manager.$globalHotkeyEnabled
            .receive(on: DispatchQueue.main)
            .sink { [weak self] enabled in
                guard let self else { return }
                if enabled {
                    let hk = HotkeyManager()
                    hk.onHotkey = { [weak self] in self?.manager.toggle() }
                    hk.register(); hotkeyManager = hk
                } else { hotkeyManager = nil }
            }
            .store(in: &cancellables)
    }
}

// MARK: - NSPopoverDelegate

extension AppDelegate: NSPopoverDelegate {
    func popoverDidClose(_ notification: Notification) {
        suppressNextOpen = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) { [weak self] in
            self?.suppressNextOpen = false
        }
    }
}

