import SwiftUI

struct MenuBarView: View {
    @EnvironmentObject var manager: CaffeinateManager

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack(spacing: 10) {
                Image(systemName: manager.isActive ? "cup.and.saucer.fill" : "cup.and.saucer")
                    .font(.system(size: 28))
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
                        Text("Tap to keep display on")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)

            Divider()

            // Toggle button
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
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .keyboardShortcut("k", modifiers: .command)
            .background(
                RoundedRectangle(cornerRadius: 6)
                    .fill(Color.accentColor.opacity(0.08))
                    .padding(.horizontal, 8)
            )
            .padding(.vertical, 4)

            Divider()

            // Quit
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
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .keyboardShortcut("q", modifiers: .command)
            .padding(.vertical, 4)
        }
        .frame(width: 260)
    }

    private var formattedElapsed: String {
        let s = manager.elapsedSeconds
        if s < 60 { return "\(s)s" }
        let m = s / 60
        if m < 60 { return "\(m)m \(s % 60)s" }
        return "\(m / 60)h \(m % 60)m"
    }
}

#Preview {
    MenuBarView()
        .environmentObject(CaffeinateManager())
}
