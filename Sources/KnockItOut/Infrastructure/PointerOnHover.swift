import AppKit
import SwiftUI

struct PointerOnHover: ViewModifier {
    func body(content: Content) -> some View {
        content.onHover { hovering in
            if hovering {
                NSCursor.pointingHand.push()
            } else {
                NSCursor.pop()
            }
        }
    }
}

extension View {
    func pointingHandOnHover() -> some View {
        modifier(PointerOnHover())
    }
}
