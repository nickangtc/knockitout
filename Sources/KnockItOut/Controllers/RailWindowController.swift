import AppKit
import SwiftUI

@MainActor
final class RailWindowController {
    private let store: KnockItemStore
    private var window: NSWindow?
    private var screen: NSScreen { NSScreen.main ?? NSScreen.screens.first! }

    init(store: KnockItemStore) { self.store = store }

    func refresh() {
        if store.items.isEmpty {
            window?.orderOut(nil)
            window = nil
            return
        }
        let frame = ScreenPlacement.railFrame(for: screen, itemCount: store.items.count, reservesToastSpace: store.lastUndo != nil)
        if let window {
            if !NSEqualRects(window.frame, frame) {
                window.setFrame(frame, display: true, animate: false)
            }
            return
        }
        let window = ClickThroughHostingWindow(contentRect: frame, styleMask: [.borderless], backing: .buffered, defer: false)
        window.backgroundColor = .clear
        window.isOpaque = false
        window.level = .floating
        window.hasShadow = false
        window.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        window.contentView = NSHostingView(rootView: RailView(store: store))
        self.window = window
        window.orderFrontRegardless()
        window.acceptsMouseMovedEvents = true
    }
}
