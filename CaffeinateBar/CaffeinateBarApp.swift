import SwiftUI

@main
struct CaffeinateBarApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        // All UI is managed via NSStatusItem in AppDelegate.
        // This Settings scene prevents SwiftUI from opening any windows.
        Settings { EmptyView() }
    }
}
