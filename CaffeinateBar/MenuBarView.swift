import SwiftUI

struct MenuBarView: View {
    @EnvironmentObject var manager: CaffeinateManager

    var body: some View {
        VStack(spacing: 0) {
            headerSection
            Divider()
            assertionsSection
            Divider()
            timeoutSection
            Divider()
            commandPreviewSection
            Divider()
            actionSection
        }
        .frame(width: 290)
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
                subtitle: "Keeps the screen on"
            )
            AssertionRow(
                flag: $manager.flagIdle,
                isLocked: manager.isActive,
                symbol: "moon.zzz",
                shortFlag: "-i",
                title: "Prevent idle sleep",
                subtitle: "System stays awake"
            )
            AssertionRow(
                flag: $manager.flagDisk,
                isLocked: manager.isActive,
                symbol: "internaldrive",
                shortFlag: "-m",
                title: "Prevent disk sleep",
                subtitle: "Disk stays spinning"
            )
            AssertionRow(
                flag: $manager.flagSystem,
                isLocked: manager.isActive,
                symbol: "bolt",
                shortFlag: "-s",
                title: "Prevent system sleep",
                subtitle: "AC power only"
            )
        }
        .padding(.bottom, 4)
    }

    // MARK: - Timeout

    private var timeoutSection: some View {
        VStack(alignment: .leading, spacing: 6) {
            sectionHeader("TIMEOUT  (-t)")

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

#Preview {
    MenuBarView()
        .environmentObject(CaffeinateManager())
}
