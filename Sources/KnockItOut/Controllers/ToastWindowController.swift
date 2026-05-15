import AppKit
import SwiftUI

@MainActor
final class ToastWindowController {
    private let store: KnockItemStore
    private var window: NSWindow?

    init(store: KnockItemStore) { self.store = store }

    func refresh() {
        guard store.lastUndo != nil, store.items.isEmpty else {
            window?.orderOut(nil)
            window = nil
            return
        }
        let screen = NSScreen.main ?? NSScreen.screens.first!
        if window == nil {
            let window = NSWindow(contentRect: ScreenPlacement.toastFrame(for: screen), styleMask: [.borderless], backing: .buffered, defer: false)
            window.backgroundColor = .clear
            window.isOpaque = false
            window.level = .floating
            window.hasShadow = false
            window.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
            window.contentView = NSHostingView(rootView: UndoToastView(store: store))
            self.window = window
        }
        window?.orderFrontRegardless()
    }
}
