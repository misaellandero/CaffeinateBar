import SwiftUI

@main
struct CaffeinateBarApp: App {
    @StateObject private var manager = CaffeinateManager()

    var body: some Scene {
        MenuBarExtra {
            MenuBarView()
                .environmentObject(manager)
        } label: {
            let name = manager.isActive ? "cup.and.saucer.fill" : "cup.and.saucer"
            Image(systemName: name)
                .symbolRenderingMode(.hierarchical)
        }
        .menuBarExtraStyle(.window)
    }
}
