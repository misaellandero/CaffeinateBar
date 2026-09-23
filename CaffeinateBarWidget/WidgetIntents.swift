import AppIntents

/// Both intents only record the request in the shared App Group container and then
/// open the (menu-bar-only, LSUIElement) host app to carry it out — the caffeinate
/// child process is owned by CaffeinateManager there, not by this sandboxed extension.
struct ToggleCaffeinateIntent: AppIntent {
    static var title: LocalizedStringResource = "Toggle Caffeinate"
    static var openAppWhenRun: Bool = true

    func perform() async throws -> some IntentResult {
        SharedWidgetState.requestPendingAction(.toggle)
        return .result()
    }
}

struct CancelTimeoutIntent: AppIntent {
    static var title: LocalizedStringResource = "Cancel Timer"
    static var openAppWhenRun: Bool = true

    func perform() async throws -> some IntentResult {
        SharedWidgetState.requestPendingAction(.cancelTimeout)
        return .result()
    }
}
