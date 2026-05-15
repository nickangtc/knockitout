import AppKit
import SwiftUI

@MainActor
final class CelebrationWindowController {
    private var window: NSWindow?

    func show(anchor: CGPoint? = nil) {
        let screen = NSScreen.main ?? NSScreen.screens.first!
        var frame = ScreenPlacement.celebrationFrame(for: screen)
        if let anchor {
            frame.origin = CGPoint(x: anchor.x - frame.width / 2, y: anchor.y - frame.height / 2)
        }
        let window = NSWindow(contentRect: frame, styleMask: [.borderless], backing: .buffered, defer: false)
        window.backgroundColor = .clear
        window.isOpaque = false
        window.level = .floating
        window.hasShadow = false
        window.ignoresMouseEvents = true
        window.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        window.contentView = NSHostingView(rootView: CelebrationView())
        self.window = window
        window.orderFrontRegardless()
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.35) { [weak self] in
            self?.window?.orderOut(nil)
            self?.window = nil
        }
    }
}
