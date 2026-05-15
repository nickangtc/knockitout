import AppKit
import SwiftUI

@MainActor
final class WelcomeWindowController {
    private var window: NSWindow?
    private let settings: AppSettingsStore
    private let startLauncher: () -> Void

    init(settings: AppSettingsStore, startLauncher: @escaping () -> Void) {
        self.settings = settings
        self.startLauncher = startLauncher
    }

    func show() {
        let view = WelcomeView { [weak self] enabled in
            guard let self else { return }
            self.settings.applyLaunchAtLogin(enabled)
            self.settings.hasCompletedFirstRunWelcome = true
            self.window?.close()
            self.window = nil
            self.startLauncher()
        }
        let window = NSWindow(contentRect: NSRect(x: 0, y: 0, width: 430, height: 250), styleMask: [.titled, .closable], backing: .buffered, defer: false)
        window.title = "Knock It Out"
        window.isReleasedWhenClosed = false
        window.contentView = NSHostingView(rootView: view)
        window.center()
        self.window = window
        NSApp.activate(ignoringOtherApps: true)
        window.makeKeyAndOrderFront(nil)
    }
}
