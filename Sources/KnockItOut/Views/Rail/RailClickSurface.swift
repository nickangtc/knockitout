import AppKit
import SwiftUI

struct RailClickSurface: NSViewRepresentable {
    let onSingleClick: () -> Void
    let onDoubleClick: () -> Void

    func makeNSView(context: Context) -> ClickView {
        let view = ClickView()
        view.onSingleClick = onSingleClick
        view.onDoubleClick = onDoubleClick
        return view
    }

    func updateNSView(_ nsView: ClickView, context: Context) {
        nsView.onSingleClick = onSingleClick
        nsView.onDoubleClick = onDoubleClick
    }

    final class ClickView: NSView {
        var onSingleClick: (() -> Void)?
        var onDoubleClick: (() -> Void)?

        override var acceptsFirstResponder: Bool { true }

        override func resetCursorRects() {
            addCursorRect(bounds, cursor: .pointingHand)
        }

        override func mouseDown(with event: NSEvent) {
            if event.clickCount >= 2 {
                onDoubleClick?()
            } else {
                onSingleClick?()
            }
        }
    }
}
