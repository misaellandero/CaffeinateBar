import SwiftUI

// MARK: - Root View

struct MenuBarView: View {
    @EnvironmentObject var manager: CaffeinateManager
    @State private var selectedTab = 0

    var body: some View {
        VStack(spacing: 0) {
            // Content area — fixed height, no scroll
            Group {
                if selectedTab == 0 {
                    HomeTab()
                } else {
                    SettingsTab()
                }
            }
            .environmentObject(manager)
            .frame(width: 290, height: 362)

            Divider()

            // Bottom tab bar
            BottomTabBar(selectedTab: $selectedTab, manager: manager)
        }
        .frame(width: 290)
    }
}

// MARK: - Home Tab

private struct HomeTab: View {
    @EnvironmentObject var manager: CaffeinateManager

    var body: some View {
        VStack(spacing: 0) {
            // ── Status header ──────────────────────────────
            HStack(spacing: 10) {
                Image(systemName: manager.isActive ? "cup.and.saucer.fill" : "cup.and.saucer")
                    .font(.system(size: 24))
                    .symbolRenderingMode(.hierarchical)
                    .foregroundStyle(manager.isActive ? .brown : .secondary)

                VStack(alignment: .leading, spacing: 2) {
                    Text(manager.isActive ? "Display Awake" : "Sleep Allowed")
                        .font(.headline)
                    Text(manager.isActive ? "Active for \(formattedElapsed)" : "Configure below, then enable")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Circle()
                    .fill(manager.isActive ? Color.green : Color.secondary.opacity(0.35))
                    .frame(width: 9, height: 9)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 10)

            Divider()

            // ── Big toggle button ──────────────────────────
            Button { manager.toggle() } label: {
                HStack {
                    Image(systemName: manager.isActive ? "moon.zzz.fill" : "sun.max.fill")
                        .font(.system(size: 15, weight: .semibold))
                    Text(manager.isActive ? "Disable Caffeinate" : "Enable Caffeinate")
                        .font(.headline)
                    Spacer()
                    Text("⌘K").font(.caption).foregroundStyle(.tertiary)
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 11)
                .background(manager.isActive
                    ? Color.orange.opacity(0.10)
                    : Color.accentColor.opacity(0.08))
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .keyboardShortcut("k", modifiers: .command)

            Divider()

            // ── Assertions ────────────────────────────────
            rowHeader("ASSERTIONS")

            AssertionRow(flag: $manager.flagDisplay, isLocked: manager.isActive,
                         symbol: "display",       shortFlag: "-d",
                         title: "Prevent display sleep",
                         info: "Your screen will stay fully lit no matter how long you leave it. Perfect for presentations, cooking recipes, or any time you don't want the display to go dark while you step away.")

            AssertionRow(flag: $manager.flagIdle,    isLocked: manager.isActive,
                         symbol: "moon.zzz",       shortFlag: "-i",
                         title: "Prevent idle sleep",
                         info: "Stops your Mac from dozing off when you're not actively using it. Your screen might still dim to save power, but the computer keeps running in the background — great for long downloads or remote connections.")

            AssertionRow(flag: $manager.flagDisk,    isLocked: manager.isActive,
                         symbol: "internaldrive",  shortFlag: "-m",
                         title: "Prevent disk sleep",
                         info: "Keeps your hard drive spinning and ready at all times. Useful during large file transfers, backups, or video exports where a sleeping disk could slow things down or cause errors.")

            AssertionRow(flag: $manager.flagSystem,  isLocked: manager.isActive,
                         symbol: "bolt",           shortFlag: "-s",
                         title: "Prevent system sleep",
                         info: "Prevents your Mac from sleeping entirely — even on a schedule. Only works when your Mac is plugged into a power adapter. Handy for overnight tasks like rendering, compiling, or running a local server.")

            Divider()

            // ── Timeout ───────────────────────────────────
            HStack(spacing: 4) {
                rowHeader("TIMEOUT  (-t)")
                Image(systemName: "info.circle")
                    .font(.system(size: 10))
                    .foregroundStyle(.tertiary)
                    .help("Automatically stops Caffeinate after the selected time. Handy if you only need your Mac awake for a meeting or a movie — it goes back to normal sleep on its own.")
                    .padding(.top, 6)
                Spacer()
                Picker("", selection: $manager.timeoutPreset) {
                    ForEach(TimeoutPreset.allCases) { p in
                        Text(p.label).tag(p)
                    }
                }
                .pickerStyle(.menu)
                .disabled(manager.isActive)
                .labelsHidden()
                .padding(.trailing, 10)
                .padding(.top, 4)
            }

            Divider()

            // ── Command preview ───────────────────────────
            HStack(spacing: 6) {
                Image(systemName: "terminal").font(.caption).foregroundStyle(.tertiary)
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

            Spacer(minLength: 0)
        }
    }

    private func rowHeader(_ text: String) -> some View {
        Text(text)
            .font(.system(size: 10, weight: .semibold))
            .foregroundStyle(.tertiary)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 14)
            .padding(.top, 7)
            .padding(.bottom, 2)
    }

    private var formattedElapsed: String {
        let s = manager.elapsedSeconds
        if s < 60 { return "\(s)s" }
        let m = s / 60
        return m < 60 ? "\(m)m \(s % 60)s" : "\(m / 60)h \(m % 60)m"
    }
}

// MARK: - Settings Tab

private struct SettingsTab: View {
    @EnvironmentObject var manager: CaffeinateManager

    var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(spacing: 0) {
                sectionHeader("GENERAL")

                SettingsRow(toggle: $manager.launchAtLogin,
                            symbol: "power", title: "Launch at Login",
                            info: "Automatically starts CaffeinateBar when you log in, so it's always ready in your menu bar without needing to open it manually.")

                SettingsRow(toggle: $manager.activateOnLaunch,
                            symbol: "play.fill", title: "Activate on Launch",
                            info: "Automatically enables Caffeinate every time the app starts. Great if you always want your Mac to stay awake as soon as you open it.")

                SettingsRow(toggle: $manager.leftClickToToggle,
                            symbol: "cursorarrow.click", title: "Left Click to Toggle",
                            info: "A single left-click on the menu bar icon will toggle Caffeinate on or off directly, instead of opening this window. Right-click still opens the window.")

                SettingsRow(toggle: $manager.globalHotkeyEnabled,
                            symbol: "keyboard", title: "Global Shortcut  ⌥⌘K",
                            info: "Press Option + Command + K from anywhere on your Mac to toggle Caffeinate on or off — even when this window is closed or another app is in focus.")

                Divider().padding(.horizontal, 14).padding(.vertical, 4)
                sectionHeader("DISPLAY & SLEEP")

                SettingsRow(
                    toggle: Binding(
                        get:  { !manager.flagDisplay },
                        set:  { manager.flagDisplay = !$0 }
                    ),
                    symbol: "moon", title: "Allow Screen to Sleep",
                    info: "Lets the display turn off while still keeping your Mac awake in the background. Saves screen power but keeps the computer running — great for overnight tasks.")

                SettingsRow(toggle: $manager.activateOnACPower,
                            symbol: "bolt.fill", title: "Activate When Plugged In",
                            info: "Automatically turns on Caffeinate whenever you connect your power adapter, so your Mac stays awake while charging without any manual steps.")

                SettingsRow(toggle: $manager.deactivateOnUnplug,
                            symbol: "bolt.slash", title: "Deactivate When Unplugged",
                            info: "Automatically turns off Caffeinate when you unplug the charger, letting your Mac sleep normally on battery to preserve power.")

                Divider().padding(.horizontal, 14).padding(.vertical, 4)
                sectionHeader("NOTIFICATIONS & APPEARANCE")

                SettingsRow(toggle: $manager.allowNotifications,
                            symbol: "bell", title: "Show Notifications",
                            info: "Sends a system notification whenever Caffeinate is turned on or off, so you always know the current state even when the menu bar is out of sight.")

                SettingsRow(toggle: $manager.colorIcon,
                            symbol: "paintpalette", title: "Color Menu Bar Icon",
                            info: "Displays the coffee cup icon in color — brown when active — instead of the standard black and white. Makes it easier to spot your caffeinate status at a glance.")
            }
            .padding(.bottom, 8)
        }
    }

    private func sectionHeader(_ text: String) -> some View {
        Text(text)
            .font(.system(size: 10, weight: .semibold))
            .foregroundStyle(.tertiary)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 14)
            .padding(.top, 10)
            .padding(.bottom, 3)
    }
}

// MARK: - Bottom Tab Bar

private struct BottomTabBar: View {
    @Binding var selectedTab: Int
    let manager: CaffeinateManager

    var body: some View {
        HStack(spacing: 0) {
            tabButton(index: 0,
                      symbol: selectedTab == 0 ? "cup.and.saucer.fill" : "cup.and.saucer",
                      label: "Caffeinate")

            Divider().frame(height: 22)

            tabButton(index: 1,
                      symbol: selectedTab == 1 ? "gearshape.fill" : "gearshape",
                      label: "Settings")

            Divider().frame(height: 22)

            // Quit
            Button { NSApplication.shared.terminate(nil) } label: {
                VStack(spacing: 2) {
                    Image(systemName: "power").font(.system(size: 12))
                    Text("Quit").font(.system(size: 9))
                }
                .foregroundStyle(.secondary)
                .frame(width: 66, height: 44)
            }
            .buttonStyle(.plain)
            .keyboardShortcut("q", modifiers: .command)
        }
        .frame(height: 44)
        .background(Color(NSColor.windowBackgroundColor))
    }

    private func tabButton(index: Int, symbol: String, label: String) -> some View {
        Button { withAnimation(.easeInOut(duration: 0.15)) { selectedTab = index } } label: {
            VStack(spacing: 2) {
                Image(systemName: symbol).font(.system(size: 12, weight: .medium))
                Text(label).font(.system(size: 9))
            }
            .foregroundStyle(selectedTab == index ? Color.accentColor : .secondary)
            .frame(maxWidth: .infinity)
            .frame(height: 44)
            .background(selectedTab == index
                ? Color.accentColor.opacity(0.06)
                : Color.clear)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - AssertionRow

private struct AssertionRow: View {
    @Binding var flag: Bool
    let isLocked: Bool
    let symbol: String
    let shortFlag: String
    let title: String
    let info: String

    var body: some View {
        Button { if !isLocked { flag.toggle() } } label: {
            HStack(spacing: 10) {
                Image(systemName: symbol)
                    .frame(width: 18)
                    .foregroundStyle(flag ? Color.accentColor : Color.secondary)

                HStack(spacing: 4) {
                    Text(title).font(.subheadline)
                    Text(shortFlag)
                        .font(.system(size: 10, design: .monospaced))
                        .foregroundStyle(.secondary)
                    Image(systemName: "info.circle")
                        .font(.system(size: 10))
                        .foregroundStyle(.tertiary)
                        .help(info)
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
                Text(title).font(.subheadline)
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
        .padding(.vertical, 7)
    }
}

// MARK: - Preview

#Preview {
    MenuBarView()
        .environmentObject(CaffeinateManager())
}
