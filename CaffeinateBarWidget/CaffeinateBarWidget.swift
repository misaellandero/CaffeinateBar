import SwiftUI
import WidgetKit

struct CaffeinateEntry: TimelineEntry {
    let date: Date
    let isActive: Bool
    let startedAt: Date?
}

struct CaffeinateProvider: TimelineProvider {
    func placeholder(in context: Context) -> CaffeinateEntry {
        CaffeinateEntry(date: Date(), isActive: true, startedAt: Date().addingTimeInterval(-900))
    }

    func getSnapshot(in context: Context, completion: @escaping (CaffeinateEntry) -> Void) {
        completion(currentEntry())
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<CaffeinateEntry>) -> Void) {
        let entry = currentEntry()
        let nextRefresh = Calendar.current.date(byAdding: .minute, value: 15, to: Date()) ?? Date().addingTimeInterval(900)
        completion(Timeline(entries: [entry], policy: .after(nextRefresh)))
    }

    private func currentEntry() -> CaffeinateEntry {
        let defaults = SharedWidgetState.defaults
        return CaffeinateEntry(
            date: Date(),
            isActive: defaults.bool(forKey: SharedWidgetState.isActiveKey),
            startedAt: defaults.object(forKey: SharedWidgetState.startedAtKey) as? Date
        )
    }
}

struct CaffeinateBarWidgetEntryView: View {
    @Environment(\.widgetFamily) private var family
    let entry: CaffeinateEntry

    var body: some View {
        content
            .widgetURL(SharedWidgetState.launchURL)
            .widgetBackground()
    }

    private var content: some View {
        VStack(alignment: .leading, spacing: family == .systemSmall ? 10 : 14) {
            HStack(alignment: .center, spacing: 8) {
                Image(systemName: "cup.and.saucer.fill")
                    .font(.system(size: family == .systemSmall ? 22 : 28, weight: .semibold))
                    .symbolRenderingMode(.palette)
                    .foregroundStyle(entry.isActive ? .green : .secondary, .orange.opacity(0.35))

                Spacer(minLength: 0)

                Circle()
                    .fill(entry.isActive ? .green : .secondary.opacity(0.35))
                    .frame(width: 10, height: 10)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(entry.isActive ? "Awake" : "Sleep Allowed")
                    .font(.headline)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)

                if entry.isActive, let startedAt = entry.startedAt {
                    Text(startedAt, style: .timer)
                        .font(.system(.title3, design: .rounded).weight(.semibold))
                        .monospacedDigit()
                } else {
                    Text("Tap to open")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }

            if family != .systemSmall {
                Spacer(minLength: 0)
                Text(entry.isActive ? "Caffeinate is keeping this computer awake." : "Open CaffeinateBar to start a session.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            }
        }
        .padding()
    }
}

struct CaffeinateBarWidget: Widget {
    let kind = "CaffeinateStatusWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: CaffeinateProvider()) { entry in
            CaffeinateBarWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("Caffeinate Bar")
        .description("See whether Caffeinate is keeping your computer awake.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

@main
struct CaffeinateBarWidgetBundle: WidgetBundle {
    var body: some Widget {
        CaffeinateBarWidget()
    }
}

private extension View {
    @ViewBuilder
    func widgetBackground() -> some View {
        if #available(macOS 14.0, *) {
            containerBackground(.background, for: .widget)
        } else {
            background(Color(NSColor.windowBackgroundColor))
        }
    }
}
