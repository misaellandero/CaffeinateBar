import SwiftUI

// MARK: - Root

struct MenuBarView: View {
    @EnvironmentObject var manager: CaffeinateManager
    @AppStorage("sec.assertions") private var assertionsOpen = true
    @AppStorage("sec.timeout")    private var timeoutOpen    = false
    @AppStorage("sec.settings")   private var settingsOpen   = false

    var body: some View {
        VStack(spacing: 0) {
            statusHeader
            Divider()
            toggleButton
            Divider()
            accordionSection(title: "ASSERTIONS", systemImage: "slider.horizontal.3",
                             isOpen: $assertionsOpen) { assertionsContent }
            Divider()
            accordionSection(title: "TIMEOUT", systemImage: "clock",
                             isOpen: $timeoutOpen)    { timeoutContent    }
            Divider()
            accordionSection(title: "SETTINGS", systemImage: "gearshape",
                             isOpen: $settingsOpen)   { settingsContent   }
            Divider()
            commandPreview
            Divider()
            quitButton
        }
        .frame(width: 290)
    }

    // MARK: Status header ──────────────────────────────────────────────────

    private var statusHeader: some View {
        HStack(spacing: 10) {
            ZStack {
                Circle()
                    .fill(manager.isActive ? Color.green.opacity(0.15) : Color.clear)
                    .frame(width: 44, height: 44)
                Image(systemName: "cup.and.saucer.fill")
                    .font(.system(size: 22, weight: .medium))
                    .symbolRenderingMode(.palette)
                    .foregroundStyle(
                        manager.isActive ? Color.green : Color.secondary,
                        manager.isActive ? Color.green.opacity(0.3) : Color.secondary.opacity(0.2)
                    )
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(manager.isActive ? "Caffeinate Active" : "Sleep Allowed")
                    .font(.headline)
                if manager.isActive {
                    Text("Running for \(formattedElapsed)")
                        .font(.caption).foregroundStyle(.secondary)
                } else {
                    Text("Display can sleep normally")
                        .font(.caption).foregroundStyle(.secondary)
                }
            }
            Spacer()
            Circle()
                .fill(manager.isActive ? Color.green : Color.secondary.opacity(0.3))
                .frame(width: 9, height: 9)
                .shadow(color: manager.isActive ? .green.opacity(0.6) : .clear, radius: 4)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
    }

    // MARK: Big toggle button ──────────────────────────────────────────────

    private var toggleButton: some View {
        Button { manager.toggle() } label: {
            HStack(spacing: 10) {
                Image(systemName: manager.isActive ? "moon.zzz.fill" : "sun.max.fill")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(manager.isActive ? .orange : .yellow)
                    .frame(width: 24)
                Text(manager.isActive ? "Disable Caffeinate" : "Enable Caffeinate")
                    .font(.system(size: 14, weight: .semibold))
                Spacer()
                Text("⌘K").font(.caption).foregroundStyle(.tertiary)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 11)
            .background(
                manager.isActive
                    ? Color.orange.opacity(0.10)
                    : Color.accentColor.opacity(0.07)
            )
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .keyboardShortcut("k", modifiers: .command)
    }

    // MARK: Accordion wrapper ──────────────────────────────────────────────

    @ViewBuilder
    private func accordionSection<Content: View>(
        title: String,
        systemImage: String,
        isOpen: Binding<Bool>,
        @ViewBuilder content: @escaping () -> Content
    ) -> some View {
        VStack(spacing: 0) {
            // Header row
            Button {
                withAnimation(.easeInOut(duration: 0.18)) { isOpen.wrappedValue.toggle() }
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: systemImage)
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(.secondary)
                        .frame(width: 16)
                    Text(title)
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundStyle(.secondary)
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.system(size: 9, weight: .bold))
                        .foregroundStyle(.tertiary)
                        .rotationEffect(.degrees(isOpen.wrappedValue ? 90 : 0))
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 7)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

            // Expanded content
            if isOpen.wrappedValue {
                content()
                    .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
    }

    // MARK: Assertions ─────────────────────────────────────────────────────

    private var assertionsContent: some View {
        VStack(spacing: 0) {
            Divider().padding(.horizontal, 14)
            AssertionRow(flag: $manager.flagDisplay, isLocked: manager.isActive,
                symbol: "display", shortFlag: "-d", title: "Prevent display sleep",
                tip: "Keeps the screen fully lit — great for presentations or recipes.")
            AssertionRow(flag: $manager.flagIdle, isLocked: manager.isActive,
                symbol: "moon.zzz", shortFlag: "-i", title: "Prevent idle sleep",
                tip: "Mac keeps running in the background — perfect for downloads or remote connections.")
            AssertionRow(flag: $manager.flagDisk, isLocked: manager.isActive,
                symbol: "internaldrive", shortFlag: "-m", title: "Prevent disk sleep",
                tip: "Disk stays ready — useful for backups or long video exports.")
            AssertionRow(flag: $manager.flagSystem, isLocked: manager.isActive,
                symbol: "bolt", shortFlag: "-s", title: "Prevent system sleep",
                tip: "No sleep at all — AC power only. Good for overnight server tasks.")
        }
    }

    // MARK: Timeout ────────────────────────────────────────────────────────

    private var timeoutContent: some View {
        VStack(spacing: 0) {
            Divider().padding(.horizontal, 14)
            HStack {
                Image(systemName: "timer")
                    .font(.system(size: 13))
                    .foregroundStyle(.secondary)
                    .frame(width: 20)
                Text("Stop after")
                    .font(.subheadline)
                Spacer()
                Picker("", selection: $manager.timeoutPreset) {
                    ForEach(TimeoutPreset.allCases) { p in
                        Text(p.label).tag(p)
                    }
                }
                .pickerStyle(.menu)
                .labelsHidden()
                .disabled(manager.isActive)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 9)
        }
    }

    // MARK: Settings ───────────────────────────────────────────────────────

    private var settingsContent: some View {
        VStack(spacing: 0) {
            Divider().padding(.horizontal, 14)

            settingsGroup("GENERAL") {
                SettingsRow(toggle: $manager.launchAtLogin,
                    symbol: "power", title: "Launch at Login",
                    tip: "Starts CaffeinateBar automatically when you log in.")
                SettingsRow(toggle: $manager.activateOnLaunch,
                    symbol: "play.fill", title: "Activate on Launch",
                    tip: "Automatically enables Caffeinate every time the app opens.")
                SettingsRow(toggle: $manager.leftClickToToggle,
                    symbol: "cursorarrow.click", title: "Left Click to Toggle",
                    tip: "One click on the icon toggles Caffeinate. Right-click still opens this window.")
                SettingsRow(toggle: $manager.globalHotkeyEnabled,
                    symbol: "keyboard", title: "Shortcut  ⌥⌘K",
                    tip: "Toggle Caffeinate from anywhere with Option+Command+K.")
            }

            settingsDivider("SLEEP & POWER")

            SettingsRow(
                toggle: Binding(get: { !manager.flagDisplay }, set: { manager.flagDisplay = !$0 }),
                symbol: "moon", title: "Allow Screen to Sleep",
                tip: "Screen can turn off while Mac stays awake — saves power during overnight tasks.")
            SettingsRow(toggle: $manager.activateOnACPower,
                symbol: "bolt.fill", title: "Activate When Plugged In",
                tip: "Auto-enables Caffeinate whenever you connect the power adapter.")
            SettingsRow(toggle: $manager.deactivateOnUnplug,
                symbol: "bolt.slash", title: "Deactivate When Unplugged",
                tip: "Auto-disables Caffeinate when the charger is removed to save battery.")

            settingsDivider("APPEARANCE")

            SettingsRow(toggle: $manager.allowNotifications,
                symbol: "bell", title: "Show Notifications",
                tip: "Get a system notification when Caffeinate turns on or off.")
            SettingsRow(toggle: $manager.colorIcon,
                symbol: "paintpalette", title: "Color Icon",
                tip: "Show a colored icon (green when active) instead of the system default.")
        }
    }

    @ViewBuilder
    private func settingsGroup<Content: View>(_ label: String,
                                              @ViewBuilder content: () -> Content) -> some View {
        content()
    }

    private func settingsDivider(_ label: String) -> some View {
        HStack {
            Text(label)
                .font(.system(size: 9, weight: .semibold))
                .foregroundStyle(.quaternary)
            VStack { Divider() }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 4)
    }

    // MARK: Command preview ────────────────────────────────────────────────

    private var commandPreview: some View {
        HStack(spacing: 6) {
            Image(systemName: "terminal").font(.caption2).foregroundStyle(.tertiary)
            Text(manager.commandPreview)
                .font(.system(.caption2, design: .monospaced))
                .foregroundStyle(.tertiary)
                .lineLimit(1).truncationMode(.tail)
            Spacer()
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 6)
        .background(Color(NSColor.controlBackgroundColor))
    }

    // MARK: Quit button ────────────────────────────────────────────────────

    private var quitButton: some View {
        Button { NSApplication.shared.terminate(nil) } label: {
            HStack {
                Image(systemName: "power").font(.system(size: 12))
                Text("Quit CaffeinateBar").font(.subheadline)
                Spacer()
                Text("⌘Q").font(.caption).foregroundStyle(.tertiary)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .keyboardShortcut("q", modifiers: .command)
    }

    // MARK: Helpers ────────────────────────────────────────────────────────

    private var formattedElapsed: String {
        let s = manager.elapsedSeconds
        if s < 60 { return "\(s)s" }
        let m = s / 60
        return m < 60 ? "\(m)m \(s % 60)s" : "\(m / 60)h \(m % 60)m"
    }
}

// MARK: - AssertionRow

private struct AssertionRow: View {
    @Binding var flag: Bool
    let isLocked: Bool
    let symbol: String
    let shortFlag: String
    let title: String
    let tip: String

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: symbol)
                .font(.system(size: 13))
                .foregroundStyle(flag ? Color.accentColor : Color.secondary)
                .frame(width: 20)
            Text(title).font(.subheadline)
            Text(shortFlag)
                .font(.system(size: 10, design: .monospaced))
                .foregroundStyle(.tertiary)
            Spacer()
            Toggle("", isOn: $flag)
                .toggleStyle(.switch).labelsHidden()
                .disabled(isLocked)
                .scaleEffect(0.8)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 5)
        .opacity(isLocked ? 0.5 : 1.0)
        .help(tip)
        .contentShape(Rectangle())
        .onTapGesture { if !isLocked { flag.toggle() } }
    }
}

// MARK: - SettingsRow

private struct SettingsRow: View {
    @Binding var toggle: Bool
    let symbol: String
    let title: String
    let tip: String

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: symbol)
                .font(.system(size: 13))
                .foregroundStyle(.secondary)
                .frame(width: 20)
            Text(title).font(.subheadline)
            Spacer()
            Toggle("", isOn: $toggle)
                .toggleStyle(.switch).labelsHidden()
                .scaleEffect(0.8)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 6)
        .help(tip)
    }
}

#Preview {
    MenuBarView().environmentObject(CaffeinateManager())
}
