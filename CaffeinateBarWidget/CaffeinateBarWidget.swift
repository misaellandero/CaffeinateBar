import SwiftUI
import WidgetKit

struct CaffeinateEntry: TimelineEntry {
    let date: Date
    let isActive: Bool
    let startedAt: Date?
    let hasTimeout: Bool
}

struct CaffeinateProvider: TimelineProvider {
    func placeholder(in context: Context) -> CaffeinateEntry {
        CaffeinateEntry(date: Date(), isActive: true, startedAt: Date().addingTimeInterval(-900), hasTimeout: false)
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
            startedAt: defaults.object(forKey: SharedWidgetState.startedAtKey) as? Date,
            hasTimeout: defaults.integer(forKey: SharedWidgetState.timeoutPresetKey) != 0
        )
    }
}

struct CaffeinateBarWidgetEntryView: View {
    @Environment(\.widgetFamily) private var family
    let entry: CaffeinateEntry

    var body: some View {
        Group {
            if family == .systemSmall {
                statusColumn
            } else {
                HStack(alignment: .top, spacing: 12) {
                    statusColumn
                    Spacer(minLength: 8)
                    actionColumn
                }
            }
        }
        .padding()
        .widgetURL(SharedWidgetState.launchURL)
        .containerBackground(.background, for: .widget)
    }

    private var statusColumn: some View {
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
                Text(entry.isActive ? LocalizedStringKey("Awake") : LocalizedStringKey("Sleep Allowed"))
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
                Text(entry.isActive ? LocalizedStringKey("Caffeinate is keeping this computer awake.") : LocalizedStringKey("Open CaffeinateBar to start a session."))
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            }
        }
    }

    // Only the larger family has room for the interactive controls.
    private var actionColumn: some View {
        VStack(spacing: 8) {
            Button(intent: ToggleCaffeinateIntent()) {
                Image(systemName: entry.isActive ? "stop.fill" : "play.fill")
                    .font(.system(size: 14, weight: .semibold))
                    .frame(width: 30, height: 30)
            }
            .buttonStyle(.plain)
            .background(Circle().fill((entry.isActive ? Color.orange : Color.green).opacity(0.15)))
            .foregroundStyle(entry.isActive ? .orange : .green)

            if entry.isActive && entry.hasTimeout {
                Button(intent: CancelTimeoutIntent()) {
                    Image(systemName: "xmark")
                        .font(.system(size: 12, weight: .semibold))
                        .frame(width: 30, height: 30)
                }
                .buttonStyle(.plain)
                .background(Circle().fill(Color.secondary.opacity(0.15)))
                .foregroundStyle(.secondary)
            }
        }
    }
}

struct CaffeinateBarWidget: Widget {
    let kind = "CaffeinateStatusWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: CaffeinateProvider()) { entry in
            CaffeinateBarWidgetEntryView(entry: entry)
        }
        .configurationDisplayName(LocalizedStringResource("Caffeinate Bar"))
        .description(LocalizedStringResource("See whether Caffeinate is keeping your computer awake."))
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

@main
struct CaffeinateBarWidgetBundle: WidgetBundle {
    var body: some Widget {
        CaffeinateBarWidget()
    }
}
