import SwiftUI

struct MenuBarView: View {
    @EnvironmentObject var manager: CaffeinateManager
    @AppStorage("settingsExpanded") private var settingsExpanded: Bool = false

    var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(spacing: 0) {
                headerSection
                Divider()
                assertionsSection
                Divider()
                timeoutSection
                Divider()
                commandPreviewSection
                Divider()
                settingsSection
                Divider()
                actionSection
            }
        }
        .frame(width: 290, height: settingsExpanded ? 530 : 320)
    }

    // MARK: - Header

    private var headerSection: some View {
        HStack(spacing: 10) {
            Image(systemName: manager.isActive ? "cup.and.saucer.fill" : "cup.and.saucer")
                .font(.system(size: 26))
                .symbolRenderingMode(.hierarchical)
                .foregroundStyle(manager.isActive ? .brown : .secondary)

            VStack(alignment: .leading, spacing: 2) {
                Text(manager.isActive ? "Display Awake" : "Display Sleep Allowed")
                    .font(.headline)
                if manager.isActive {
                    Text("Active for \(formattedElapsed)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                } else {
                    Text("Configure assertions below")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            Spacer()

            // Status dot
            Circle()
                .fill(manager.isActive ? Color.green : Color.secondary.opacity(0.4))
                .frame(width: 8, height: 8)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
    }

    // MARK: - Assertions

    private var assertionsSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            sectionHeader("ASSERTIONS")

            AssertionRow(
                flag: $manager.flagDisplay,
                isLocked: manager.isActive,
                symbol: "display",
                shortFlag: "-d",
                title: "Prevent display sleep",
                subtitle: "Keeps the screen on",
                info: "Your screen will stay fully lit no matter how long you leave it. Perfect for presentations, cooking recipes, or any time you don't want the display to go dark while you step away."
            )
            AssertionRow(
                flag: $manager.flagIdle,
                isLocked: manager.isActive,
                symbol: "moon.zzz",
                shortFlag: "-i",
                title: "Prevent idle sleep",
                subtitle: "System stays awake",
                info: "Stops your Mac from dozing off when you're not actively using it. Your screen might still dim to save power, but the computer keeps running in the background — great for long downloads or remote connections."
            )
            AssertionRow(
                flag: $manager.flagDisk,
                isLocked: manager.isActive,
                symbol: "internaldrive",
                shortFlag: "-m",
                title: "Prevent disk sleep",
                subtitle: "Disk stays spinning",
                info: "Keeps your hard drive spinning and ready at all times. Useful during large file transfers, backups, or video exports where a sleeping disk could slow things down or cause errors."
            )
            AssertionRow(
                flag: $manager.flagSystem,
                isLocked: manager.isActive,
                symbol: "bolt",
                shortFlag: "-s",
                title: "Prevent system sleep",
                subtitle: "AC power only ⚡",
                info: "Prevents your Mac from sleeping entirely — even on a schedule. Only works when your Mac is plugged into a power adapter. Handy for overnight tasks like rendering, compiling, or running a local server."
            )
        }
        .padding(.bottom, 4)
    }

    // MARK: - Timeout

    private var timeoutSection: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 4) {
                sectionHeader("TIMEOUT  (-t)")
                Image(systemName: "info.circle")
                    .font(.system(size: 10))
                    .foregroundStyle(.tertiary)
                    .help("Automatically stops Caffeinate after the selected time. Handy if you only need your Mac awake for a meeting, a movie, or a specific task — it goes back to normal sleep on its own when the timer runs out.")
                    .padding(.top, 6)
            }

            Picker("", selection: $manager.timeoutPreset) {
                ForEach(TimeoutPreset.allCases) { preset in
                    Text(preset.label).tag(preset)
                }
            }
            .pickerStyle(.menu)
            .disabled(manager.isActive)
            .padding(.horizontal, 14)
            .padding(.bottom, 6)
        }
    }

    // MARK: - Command Preview

    private var commandPreviewSection: some View {
        HStack(spacing: 6) {
            Image(systemName: "terminal")
                .font(.caption)
                .foregroundStyle(.secondary)
            Text(manager.commandPreview)
                .font(.system(.caption, design: .monospaced))
                .foregroundStyle(.secondary)
                .lineLimit(1)
                .truncationMode(.tail)
            Spacer()
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 7)
        .background(Color(NSColor.controlBackgroundColor))
    }

    // MARK: - Settings

    private var settingsSection: some View {
        VStack(spacing: 0) {
            // Collapsible header
            Button {
                withAnimation(.easeInOut(duration: 0.18)) {
                    settingsExpanded.toggle()
                }
            } label: {
                HStack(spacing: 10) {
                    Image(systemName: "gearshape")
                        .frame(width: 18)
                        .foregroundStyle(.secondary)
                    Text("Settings")
                        .font(.subheadline)
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundStyle(.tertiary)
                        .rotationEffect(.degrees(settingsExpanded ? 90 : 0))
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

            if settingsExpanded {
                VStack(spacing: 0) {
                    Divider().padding(.horizontal, 14)

                    SettingsRow(
                        toggle: $manager.launchAtLogin,
                        symbol: "power",
                        title: "Launch at Login",
                        info: "Automatically starts CaffeinateBar when you log in, so it's always ready in your menu bar without needing to open it manually."
                    )
                    SettingsRow(
                        toggle: $manager.activateOnLaunch,
                        symbol: "play.fill",
                        title: "Activate on Launch",
                        info: "Automatically enables Caffeinate every time the app starts. Great if you always want your Mac to stay awake as soon as you open it."
                    )
                    SettingsRow(
                        toggle: $manager.leftClickToToggle,
                        symbol: "cursorarrow.click",
                        title: "Left Click to Toggle",
                        info: "A single left-click on the menu bar icon will toggle Caffeinate on or off directly, instead of opening this settings window. Right-click still opens the window."
                    )
                    SettingsRow(
                        toggle: $manager.globalHotkeyEnabled,
                        symbol: "keyboard",
                        title: "Global Shortcut  ⌥⌘K",
                        info: "Press Option + Command + K from anywhere on your Mac to toggle Caffeinate on or off — even when this window is closed or another app is in focus."
                    )
                    SettingsRow(
                        toggle: $manager.allowScreenToSleep,
                        symbol: "moon",
                        title: "Allow Screen to Sleep",
                        info: "Lets the display turn off while still keeping your Mac awake in the background. Useful for overnight tasks — saves screen power but keeps the computer running."
                    )
                    SettingsRow(
                        toggle: $manager.allowNotifications,
                        symbol: "bell",
                        title: "Show Notifications",
                        info: "Sends a system notification whenever Caffeinate is turned on or off, so you always know the current state even when the menu bar is out of sight."
                    )
                    SettingsRow(
                        toggle: $manager.colorIcon,
                        symbol: "paintpalette",
                        title: "Color Menu Bar Icon",
                        info: "Displays the coffee cup icon in color — brown when active — instead of the standard black and white. Makes it easier to spot your caffeinate status at a glance."
                    )
                    SettingsRow(
                        toggle: $manager.activateOnACPower,
                        symbol: "bolt.fill",
                        title: "Activate When Plugged In",
                        info: "Automatically turns on Caffeinate whenever you connect your power adapter, so your Mac stays awake while charging without any manual steps."
                    )
                    SettingsRow(
                        toggle: $manager.deactivateOnUnplug,
                        symbol: "bolt.slash",
                        title: "Deactivate When Unplugged",
                        info: "Automatically turns off Caffeinate when you unplug the charger, letting your Mac sleep normally on battery to preserve power."
                    )
                }
                .transition(.opacity)
            }
        }
    }

    // MARK: - Action Buttons

    private var actionSection: some View {
        VStack(spacing: 0) {
            Button {
                manager.toggle()
            } label: {
                HStack {
                    Image(systemName: manager.isActive ? "moon.zzz.fill" : "sun.max.fill")
                    Text(manager.isActive ? "Disable Caffeinate" : "Enable Caffeinate")
                    Spacer()
                    Text("⌘K")
                        .foregroundStyle(.tertiary)
                        .font(.caption)
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .keyboardShortcut("k", modifiers: .command)

            Divider()

            Button {
                NSApplication.shared.terminate(nil)
            } label: {
                HStack {
                    Image(systemName: "power")
                    Text("Quit CaffeinateBar")
                    Spacer()
                    Text("⌘Q")
                        .foregroundStyle(.tertiary)
                        .font(.caption)
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .keyboardShortcut("q", modifiers: .command)
        }
    }

    // MARK: - Helpers

    private func sectionHeader(_ text: String) -> some View {
        Text(text)
            .font(.system(size: 10, weight: .semibold))
            .foregroundStyle(.tertiary)
            .padding(.horizontal, 14)
            .padding(.top, 8)
            .padding(.bottom, 2)
    }

    private var formattedElapsed: String {
        let s = manager.elapsedSeconds
        if s < 60 { return "\(s)s" }
        let m = s / 60
        if m < 60 { return "\(m)m \(s % 60)s" }
        return "\(m / 60)h \(m % 60)m"
    }
}

// MARK: - AssertionRow

private struct AssertionRow: View {
    @Binding var flag: Bool
    let isLocked: Bool
    let symbol: String
    let shortFlag: String
    let title: String
    let subtitle: String
    let info: String

    var body: some View {
        Button {
            if !isLocked { flag.toggle() }
        } label: {
            HStack(spacing: 10) {
                Image(systemName: symbol)
                    .frame(width: 18)
                    .foregroundStyle(flag ? .primary : .tertiary)

                VStack(alignment: .leading, spacing: 1) {
                    HStack(spacing: 4) {
                        Text(title)
                            .font(.subheadline)
                        Text(shortFlag)
                            .font(.system(size: 11, design: .monospaced))
                            .foregroundStyle(.secondary)
                        Image(systemName: "info.circle")
                            .font(.system(size: 10))
                            .foregroundStyle(.tertiary)
                            .help(info)
                    }
                    Text(subtitle)
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                }

                Spacer()

                Toggle("", isOn: $flag)
                    .toggleStyle(.switch)
                    .labelsHidden()
                    .disabled(isLocked)
                    .scaleEffect(0.75)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 5)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .disabled(isLocked)
        .opacity(isLocked ? 0.5 : 1.0)
    }
}

// MARK: - SettingsRow

private struct SettingsRow: View {
    @Binding var toggle: Bool
    let symbol: String
    let title: String
    let info: String

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: symbol)
                .frame(width: 18)
                .foregroundStyle(.secondary)

            HStack(spacing: 4) {
                Text(title)
                    .font(.subheadline)
                Image(systemName: "info.circle")
                    .font(.system(size: 10))
                    .foregroundStyle(.tertiary)
                    .help(info)
            }

            Spacer()

            Toggle("", isOn: $toggle)
                .toggleStyle(.switch)
                .labelsHidden()
                .scaleEffect(0.75)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 6)
    }
}

#Preview {
    MenuBarView()
        .environmentObject(CaffeinateManager())
}
