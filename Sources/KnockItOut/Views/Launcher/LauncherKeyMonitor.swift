import AppKit
import SwiftUI

struct LauncherKeyMonitor: NSViewRepresentable {
    let handle: (NSEvent) -> Bool

    func makeNSView(context: Context) -> MonitorView {
        let view = MonitorView()
        view.handle = handle
        context.coordinator.view = view
        context.coordinator.start()
        return view
    }

    func updateNSView(_ nsView: MonitorView, context: Context) {
        nsView.handle = handle
    }

    func makeCoordinator() -> Coordinator { Coordinator() }

    final class MonitorView: NSView {
        var handle: ((NSEvent) -> Bool)?
    }

    final class Coordinator {
        weak var view: MonitorView?
        private var monitor: Any?

        func start() {
            guard monitor == nil else { return }
            monitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
                guard let view = self?.view,
                      view.window != nil,
                      view.window?.isKeyWindow == true,
                      view.handle?(event) == true else {
                    return event
                }
                return nil
            }
        }

        deinit {
            if let monitor { NSEvent.removeMonitor(monitor) }
        }
    }
}
