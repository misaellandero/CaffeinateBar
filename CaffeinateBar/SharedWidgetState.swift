import Foundation

enum SharedWidgetState {
    static let appGroupIdentifier = "group.com.local.CaffeinateBar"
    static let isActiveKey = "widget.isActive"
    static let startedAtKey = "widget.startedAt"
    static let lastUpdatedKey = "widget.lastUpdated"
    static let launchURL = URL(string: "caffeinatebar://open")

    static var defaults: UserDefaults {
        UserDefaults(suiteName: appGroupIdentifier) ?? .standard
    }
}
