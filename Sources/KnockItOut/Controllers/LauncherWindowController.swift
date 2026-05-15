import AppKit
import SwiftUI

@MainActor
final class LauncherWindowController {
    private let store: KnockItemStore
    private var window: NSWindow?

    init(store: KnockItemStore) { self.store = store }

    func open() {
        let screen = ScreenPlacement.screenContainingCursor()
        if let window, window.isVisible {
            NSApp.activate(ignoringOtherApps: true)
            window.makeKeyAndOrderFront(nil)
            return
        }
        let window = FloatingPanelWindow(contentRect: ScreenPlacement.launcherFrame(for: screen), styleMask: [.borderless], backing: .buffered, defer: false)
        window.backgroundColor = .clear
        window.isOpaque = false
        window.level = .modalPanel
        window.hasShadow = false
        window.collectionBehavior = [.fullScreenAuxiliary]
        window.contentView = NSHostingView(rootView: LauncherView(store: store) { [weak self] in self?.close() })
        self.window = window
        NSApp.activate(ignoringOtherApps: true)
        window.makeKeyAndOrderFront(nil)
    }

    func close() {
        window?.orderOut(nil)
        window = nil
    }
}
