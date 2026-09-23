import Foundation

/// An action requested from the widget's interactive buttons, to be carried out by the
/// main app process (the caffeinate child process is owned by CaffeinateManager there —
/// the widget extension only records the request).
enum PendingWidgetAction: String {
    case toggle
    case cancelTimeout
}

enum SharedWidgetState {
    static let appGroupIdentifier = "group.com.local.CaffeinateBar"
    static let isActiveKey = "widget.isActive"
    static let startedAtKey = "widget.startedAt"
    static let lastUpdatedKey = "widget.lastUpdated"
    static let flagDisplayKey = "flagDisplay"
    static let flagIdleKey = "flagIdle"
    static let flagDiskKey = "flagDisk"
    static let flagSystemKey = "flagSystem"
    static let timeoutPresetKey = "timeoutPreset"
    static let pendingActionKey = "widget.pendingAction"
    static let launchURL = URL(string: "caffeinatebar://open")

    static var defaults: UserDefaults {
        UserDefaults(suiteName: appGroupIdentifier) ?? .standard
    }

    static func widgetURL(action: String, queryItems: [URLQueryItem] = []) -> URL? {
        var components = URLComponents()
        components.scheme = "caffeinatebar"
        components.host = action
        components.queryItems = queryItems.isEmpty ? nil : queryItems
        return components.url
    }

    /// Called from the widget extension's AppIntent — only ever touches the shared
    /// App Group container, so it's safe regardless of which process runs it.
    static func requestPendingAction(_ action: PendingWidgetAction) {
        defaults.set(action.rawValue, forKey: pendingActionKey)
    }

    /// Called from the main app (on launch and on becoming active) to pick up and
    /// clear a request left by the widget.
    static func consumePendingAction() -> PendingWidgetAction? {
        guard let raw = defaults.string(forKey: pendingActionKey) else { return nil }
        defaults.removeObject(forKey: pendingActionKey)
        return PendingWidgetAction(rawValue: raw)
    }
}
