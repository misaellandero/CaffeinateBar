import AppKit
import SwiftUI

/// Owns the app's only window. Everything else lives in the status-item popover.
final class OnboardingWindowController: NSObject, NSWindowDelegate {
    private static let completedKey = "onboarding.completed"

    private var window: NSWindow?

    var hasCompletedOnboarding: Bool {
        UserDefaults.standard.bool(forKey: Self.completedKey)
    }

    func showIfNeeded() {
        guard !hasCompletedOnboarding else { return }
        show()
    }

    func show() {
        if let window {
            window.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
            return
        }

        let hosting = NSHostingController(rootView: OnboardingView(onFinish: { [weak self] in
            self?.window?.close()
        }))
        let newWindow = NSWindow(contentViewController: hosting)
        newWindow.styleMask = [.titled, .closable]
        newWindow.title = NSLocalizedString("Welcome to CaffeinateBar", comment: "Onboarding window title")
        newWindow.isReleasedWhenClosed = false
        newWindow.delegate = self
        newWindow.center()
        window = newWindow

        newWindow.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    func windowWillClose(_ notification: Notification) {
        UserDefaults.standard.set(true, forKey: Self.completedKey)
    }
}
