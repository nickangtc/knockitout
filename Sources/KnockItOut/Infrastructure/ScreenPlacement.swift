import AppKit

enum ScreenPlacement {
    static func screenContainingCursor() -> NSScreen {
        let point = NSEvent.mouseLocation
        return NSScreen.screens.first(where: { NSMouseInRect(point, $0.frame, false) }) ?? NSScreen.main ?? NSScreen.screens.first!
    }

    static func launcherFrame(for screen: NSScreen) -> NSRect { screen.frame }

    static func railFrame(for screen: NSScreen, itemCount: Int, reservesToastSpace: Bool = false) -> NSRect {
        let width: CGFloat = 320
        let rows = max(1, itemCount)
        let toastReserve: CGFloat = reservesToastSpace ? 62 : 0
        let height = min(screen.visibleFrame.height - 80, CGFloat(rows) * 66 + 24 + toastReserve)
        return NSRect(x: screen.visibleFrame.maxX - width - 16,
                      y: screen.visibleFrame.maxY - height - 24,
                      width: width,
                      height: height)
    }

    static func toastFrame(for screen: NSScreen) -> NSRect {
        NSRect(x: screen.visibleFrame.maxX - 252, y: screen.visibleFrame.maxY - 96, width: 236, height: 52)
    }

    static func celebrationFrame(for screen: NSScreen) -> NSRect {
        NSRect(x: screen.visibleFrame.maxX - 210, y: screen.visibleFrame.maxY - 160, width: 180, height: 140)
    }
}
