import AppKit
import SwiftUI
import Combine

class AppDelegate: NSObject, NSApplicationDelegate {

    let manager = CaffeinateManager()

    private var statusItem: NSStatusItem!
    private var popover: NSPopover!
    private var hotkeyManager: HotkeyManager?
    private var cancellables = Set<AnyCancellable>()

    /// Prevents the popover from immediately reopening when the user clicks
    /// the status item to dismiss it (transient-close fires before our action).
    private var suppressNextOpen = false

    // MARK: - Launch

    func applicationDidFinishLaunching(_ notification: Notification) {
        setupStatusItem()
        setupPopover()
        setupObservers()

        if manager.activateOnLaunch {
            manager.enable()
        }
    }

    // MARK: - Status Item

    private func setupStatusItem() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        updateStatusItemIcon()

        guard let button = statusItem.button else { return }
        button.target = self
        button.action = #selector(handleClick(_:))
        button.sendAction(on: [.leftMouseUp, .rightMouseUp])
    }

    @objc private func handleClick(_ sender: NSStatusBarButton) {
        guard let event = NSApp.currentEvent else { return }

        if event.type == .rightMouseUp {
            openPopover()
            return
        }

        // Left click
        if manager.leftClickToToggle {
            if popover.isShown { popover.performClose(nil) }
            manager.toggle()
        } else {
            togglePopover()
        }
    }

    private func togglePopover() {
        if popover.isShown {
            popover.performClose(nil)
        } else if !suppressNextOpen {
            openPopover()
        }
    }

    private func openPopover() {
        guard let button = statusItem.button, !popover.isShown else { return }
        popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
        NSApp.activate(ignoringOtherApps: true)
    }

    // MARK: - Popover

    private func setupPopover() {
        let hosting = NSHostingController(
            rootView: MenuBarView().environmentObject(manager)
        )
        popover = NSPopover()
        popover.behavior = .transient
        popover.delegate = self
        popover.contentViewController = hosting
    }

    // MARK: - Observers

    private func setupObservers() {
        // Rebuild icon whenever active state or icon style changes
        Publishers.MergeMany(
            manager.$isActive.map { _ in () },
            manager.$colorIcon.map { _ in () }
        )
        .receive(on: DispatchQueue.main)
        .sink { [weak self] in self?.updateStatusItemIcon() }
        .store(in: &cancellables)

        // Register / unregister global hotkey
        manager.$globalHotkeyEnabled
            .receive(on: DispatchQueue.main)
            .sink { [weak self] enabled in
                guard let self else { return }
                if enabled {
                    let hk = HotkeyManager()
                    hk.onHotkey = { [weak self] in self?.manager.toggle() }
                    hk.register()
                    self.hotkeyManager = hk
                } else {
                    self.hotkeyManager = nil
                }
            }
            .store(in: &cancellables)
    }

    // MARK: - Icon

    func updateStatusItemIcon() {
        guard let button = statusItem.button else { return }
        let name = manager.isActive ? "cup.and.saucer.fill" : "cup.and.saucer"
        guard let base = NSImage(systemSymbolName: name, accessibilityDescription: nil) else { return }

        if manager.colorIcon {
            let color: NSColor = manager.isActive ? .systemBrown : .secondaryLabelColor
            let cfg = NSImage.SymbolConfiguration(paletteColors: [color])
            let colored = base.withSymbolConfiguration(cfg) ?? base
            colored.isTemplate = false
            button.image = colored
        } else {
            base.isTemplate = true
            button.image = base
        }
    }
}

// MARK: - NSPopoverDelegate

extension AppDelegate: NSPopoverDelegate {
    func popoverDidClose(_ notification: Notification) {
        // Suppress accidental re-open when the button click that triggered the
        // close also fires our action handler.
        suppressNextOpen = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) { [weak self] in
            self?.suppressNextOpen = false
        }
    }
}
