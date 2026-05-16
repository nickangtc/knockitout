import AppKit
import SwiftUI

struct RailClickSurface: NSViewRepresentable {
    let onSingleClick: () -> Void
    let onDoubleClick: () -> Void
    var onDragBegan: (() -> Void)?
    var onDragMoved: ((CGFloat) -> Void)?
    var onDragEnded: (() -> Void)?

    func makeNSView(context: Context) -> ClickView {
        let view = ClickView()
        view.onSingleClick = onSingleClick
        view.onDoubleClick = onDoubleClick
        view.onDragBegan = onDragBegan
        view.onDragMoved = onDragMoved
        view.onDragEnded = onDragEnded
        return view
    }

    func updateNSView(_ nsView: ClickView, context: Context) {
        nsView.onSingleClick = onSingleClick
        nsView.onDoubleClick = onDoubleClick
        nsView.onDragBegan = onDragBegan
        nsView.onDragMoved = onDragMoved
        nsView.onDragEnded = onDragEnded
    }

    final class ClickView: NSView {
        var onSingleClick: (() -> Void)?
        var onDoubleClick: (() -> Void)?
        var onDragBegan: (() -> Void)?
        var onDragMoved: ((CGFloat) -> Void)?
        var onDragEnded: (() -> Void)?

        private var mouseDownLocation: NSPoint?
        private var isDragging = false
        private static let dragThreshold: CGFloat = 4

        override var acceptsFirstResponder: Bool { true }

        override func resetCursorRects() {
            addCursorRect(bounds, cursor: .pointingHand)
        }

        override func mouseDown(with event: NSEvent) {
            mouseDownLocation = event.locationInWindow
            isDragging = false
        }

        override func mouseDragged(with event: NSEvent) {
            guard let start = mouseDownLocation else { return }
            let current = event.locationInWindow
            let dx = current.x - start.x
            let dy = current.y - start.y

            if !isDragging && (dx * dx + dy * dy) > Self.dragThreshold * Self.dragThreshold {
                isDragging = true
                onDragBegan?()
            }

            if isDragging {
                onDragMoved?(start.y - current.y)
            }
        }

        override func mouseUp(with event: NSEvent) {
            if isDragging {
                onDragEnded?()
            } else if event.clickCount >= 2 {
                onDoubleClick?()
            } else {
                onSingleClick?()
            }
            mouseDownLocation = nil
            isDragging = false
        }
    }
}
