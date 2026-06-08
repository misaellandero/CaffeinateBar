import AppKit
import Combine

class AppDelegate: NSObject, NSApplicationDelegate {

    let manager = CaffeinateManager()
    private var statusItem: NSStatusItem!
    private var hotkeyManager: HotkeyManager?
    private var cancellables = Set<AnyCancellable>()

    // MARK: - Launch

    func applicationDidFinishLaunching(_ notification: Notification) {
        setupStatusItem()
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

    // MARK: - Icon

    /// Always a filled cup. Green = active, dimmed = inactive.
    func updateIcon() {
        guard let button = statusItem.button,
              let base = NSImage(systemSymbolName: "cup.and.saucer.fill",
                                 accessibilityDescription: nil) else { return }
        let color: NSColor = manager.isActive ? .systemGreen : .tertiaryLabelColor
        let cfg = NSImage.SymbolConfiguration(paletteColors: [color])
        if let colored = base.withSymbolConfiguration(cfg) {
            colored.isTemplate = false
            button.image = colored
        }
    }

    // MARK: - Click

    @objc private func handleClick(_ sender: NSStatusBarButton) {
        guard let event = NSApp.currentEvent else { return }

        // Left click with "toggle on click" enabled
        if event.type == .leftMouseUp && manager.leftClickToToggle {
            manager.toggle()
            return
        }

        // Show native dropdown menu
        statusItem.menu = buildMenu()
        sender.performClick(nil)
        DispatchQueue.main.async { self.statusItem.menu = nil }
    }

    // MARK: - Menu Builder

    private func buildMenu() -> NSMenu {
        let menu = NSMenu()
        menu.autoenablesItems = false

        // ── Status header ─────────────────────────────────────
        let statusTitle = manager.isActive ? "☕  Caffeinate is Active" : "😴  Caffeinate is Off"
        menu.addItem(infoItem(statusTitle))

        if manager.isActive {
            menu.addItem(infoItem("    Active for \(formattedElapsed)"))
        }

        menu.addItem(.separator())

        // ── Toggle ────────────────────────────────────────────
        let toggleTitle = manager.isActive ? "Disable Caffeinate" : "Enable Caffeinate"
        let toggleItem = NSMenuItem(title: toggleTitle,
                                    action: #selector(toggleCaffeinate),
                                    keyEquivalent: "k")
        toggleItem.keyEquivalentModifierMask = .command
        toggleItem.target = self
        menu.addItem(toggleItem)

        menu.addItem(.separator())

        // ── Assertions submenu ────────────────────────────────
        let assertMenu = NSMenu(title: "Assertions")
        let locked = manager.isActive
        assertMenu.addItem(
            check("Prevent display sleep   -d",
                  on: manager.flagDisplay, sel: #selector(toggleFlagD), enabled: !locked,
                  tip: "Keeps the screen fully lit no matter how long you step away. Great for presentations, recipes, or video calls."))
        assertMenu.addItem(
            check("Prevent idle sleep   -i",
                  on: manager.flagIdle, sel: #selector(toggleFlagI), enabled: !locked,
                  tip: "Stops your Mac from dozing off when idle. The screen may still dim, but the computer keeps running — perfect for long downloads or remote connections."))
        assertMenu.addItem(
            check("Prevent disk sleep   -m",
                  on: manager.flagDisk, sel: #selector(toggleFlagM), enabled: !locked,
                  tip: "Keeps your hard drive spinning and ready. Useful during large file transfers, backups, or video exports where a sleeping disk could cause errors."))
        assertMenu.addItem(
            check("Prevent system sleep   -s  ⚡",
                  on: manager.flagSystem, sel: #selector(toggleFlagS), enabled: !locked,
                  tip: "Prevents your Mac from sleeping entirely. Only works when plugged into power. Handy for overnight renders, compiling, or running a local server."))

        let assertItem = NSMenuItem(title: "Assertions", action: nil, keyEquivalent: "")
        assertItem.submenu = assertMenu
        menu.addItem(assertItem)

        // ── Timeout submenu ───────────────────────────────────
        let timeoutMenu = NSMenu(title: "Timeout")
        timeoutMenu.addItem(infoItem("Stops Caffeinate automatically after the selected time."))
        timeoutMenu.addItem(.separator())
        for preset in TimeoutPreset.allCases {
            let item = NSMenuItem(title: preset.label,
                                  action: #selector(setTimeoutPreset(_:)),
                                  keyEquivalent: "")
            item.state = manager.timeoutPreset == preset ? .on : .off
            item.representedObject = preset.rawValue
            item.target = self
            item.isEnabled = !locked
            timeoutMenu.addItem(item)
        }
        let timeoutItem = NSMenuItem(title: "Timeout", action: nil, keyEquivalent: "")
        timeoutItem.submenu = timeoutMenu
        menu.addItem(timeoutItem)

        menu.addItem(.separator())

        // ── Settings submenu ──────────────────────────────────
        let settingsMenu = NSMenu(title: "Settings")

        settingsMenu.addItem(sectionHeader("General"))
        settingsMenu.addItem(
            check("Launch at Login", on: manager.launchAtLogin, sel: #selector(toggleLaunchAtLogin),
                  tip: "Automatically starts CaffeinateBar when you log in so it's always ready in your menu bar."))
        settingsMenu.addItem(
            check("Activate on Launch", on: manager.activateOnLaunch, sel: #selector(toggleActivateOnLaunch),
                  tip: "Automatically enables Caffeinate every time the app starts."))
        settingsMenu.addItem(
            check("Left Click to Toggle", on: manager.leftClickToToggle, sel: #selector(toggleLeftClick),
                  tip: "A single left-click on the menu bar icon toggles Caffeinate on/off instead of opening this menu. Right-click always opens the menu."))
        settingsMenu.addItem(
            check("Global Shortcut  ⌥⌘K", on: manager.globalHotkeyEnabled, sel: #selector(toggleHotkey),
                  tip: "Press Option+Command+K anywhere on your Mac to toggle Caffeinate — even when other apps are in focus."))

        settingsMenu.addItem(.separator())
        settingsMenu.addItem(sectionHeader("Sleep & Power"))
        settingsMenu.addItem(
            check("Allow Screen to Sleep", on: !manager.flagDisplay, sel: #selector(toggleScreenSleep),
                  tip: "Lets the display turn off while still keeping your Mac awake. Saves screen power during overnight tasks."))
        settingsMenu.addItem(
            check("Activate When Plugged In", on: manager.activateOnACPower, sel: #selector(toggleActivateOnAC),
                  tip: "Automatically turns on Caffeinate whenever you connect your power adapter."))
        settingsMenu.addItem(
            check("Deactivate When Unplugged", on: manager.deactivateOnUnplug, sel: #selector(toggleDeactivateOnUnplug),
                  tip: "Automatically turns off Caffeinate when you unplug the charger, letting your Mac sleep normally on battery."))

        settingsMenu.addItem(.separator())
        settingsMenu.addItem(sectionHeader("Appearance"))
        settingsMenu.addItem(
            check("Show Notifications", on: manager.allowNotifications, sel: #selector(toggleNotifications),
                  tip: "Sends a system notification whenever Caffeinate is turned on or off."))
        settingsMenu.addItem(
            check("Color Menu Bar Icon", on: manager.colorIcon, sel: #selector(toggleColorIcon),
                  tip: "Shows the icon in color (green when active) instead of adapting automatically to the system appearance."))

        let settingsItem = NSMenuItem(title: "Settings", action: nil, keyEquivalent: "")
        settingsItem.submenu = settingsMenu
        menu.addItem(settingsItem)

        menu.addItem(.separator())

        // ── Quit ──────────────────────────────────────────────
        menu.addItem(NSMenuItem(title: "Quit CaffeinateBar",
                                action: #selector(NSApplication.terminate(_:)),
                                keyEquivalent: "q"))
        return menu
    }

    // MARK: - Menu helpers

    private func infoItem(_ title: String) -> NSMenuItem {
        let item = NSMenuItem(title: title, action: nil, keyEquivalent: "")
        item.isEnabled = false
        return item
    }

    private func check(_ title: String, on: Bool,
                       sel: Selector, enabled: Bool = true,
                       tip: String? = nil) -> NSMenuItem {
        let item = NSMenuItem(title: title, action: sel, keyEquivalent: "")
        item.state = on ? .on : .off
        item.target = self
        item.isEnabled = enabled
        item.toolTip = tip
        return item
    }

    private func sectionHeader(_ title: String) -> NSMenuItem {
        let item = NSMenuItem(title: "", action: nil, keyEquivalent: "")
        item.isEnabled = false
        let attrs: [NSAttributedString.Key: Any] = [
            .font: NSFont.systemFont(ofSize: 11, weight: .semibold),
            .foregroundColor: NSColor.secondaryLabelColor
        ]
        item.attributedTitle = NSAttributedString(
            string: "  " + title.uppercased(), attributes: attrs)
        return item
    }

    private var formattedElapsed: String {
        let s = manager.elapsedSeconds
        if s < 60 { return "\(s)s" }
        let m = s / 60
        return m < 60 ? "\(m)m \(s % 60)s" : "\(m / 60)h \(m % 60)m"
    }

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
                    hk.register()
                    hotkeyManager = hk
                } else {
                    hotkeyManager = nil
                }
            }
            .store(in: &cancellables)
    }

    // MARK: - Actions

    @objc private func toggleCaffeinate()         { manager.toggle() }
    @objc private func toggleFlagD()              { manager.flagDisplay.toggle() }
    @objc private func toggleFlagI()              { manager.flagIdle.toggle() }
    @objc private func toggleFlagM()              { manager.flagDisk.toggle() }
    @objc private func toggleFlagS()              { manager.flagSystem.toggle() }
    @objc private func toggleLaunchAtLogin()      { manager.launchAtLogin.toggle() }
    @objc private func toggleActivateOnLaunch()   { manager.activateOnLaunch.toggle() }
    @objc private func toggleLeftClick()          { manager.leftClickToToggle.toggle() }
    @objc private func toggleHotkey()             { manager.globalHotkeyEnabled.toggle() }
    @objc private func toggleScreenSleep()        { manager.flagDisplay.toggle() }
    @objc private func toggleActivateOnAC()       { manager.activateOnACPower.toggle() }
    @objc private func toggleDeactivateOnUnplug() { manager.deactivateOnUnplug.toggle() }
    @objc private func toggleNotifications()      { manager.allowNotifications.toggle() }
    @objc private func toggleColorIcon()          { manager.colorIcon.toggle() }

    @objc private func setTimeoutPreset(_ item: NSMenuItem) {
        guard let raw = item.representedObject as? Int,
              let preset = TimeoutPreset(rawValue: raw) else { return }
        manager.timeoutPreset = preset
    }
}
