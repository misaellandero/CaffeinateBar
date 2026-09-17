import Foundation

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
}
