import AppKit
import Carbon

@MainActor
final class HotKeyController {
    private var hotKeyRef: EventHotKeyRef?
    private var handlerRef: EventHandlerRef?
    private let action: () -> Void

    init(action: @escaping () -> Void) { self.action = action }

    func register() {
        var eventType = EventTypeSpec(eventClass: OSType(kEventClassKeyboard), eventKind: UInt32(kEventHotKeyPressed))
        let selfPointer = UnsafeMutableRawPointer(Unmanaged.passUnretained(self).toOpaque())
        let status = InstallEventHandler(GetApplicationEventTarget(), { _, event, userData in
            guard let userData else { return noErr }
            var hotKeyID = EventHotKeyID()
            GetEventParameter(event, EventParamName(kEventParamDirectObject), EventParamType(typeEventHotKeyID), nil, MemoryLayout<EventHotKeyID>.size, nil, &hotKeyID)
            if hotKeyID.id == 1 {
                let controller = Unmanaged<HotKeyController>.fromOpaque(userData).takeUnretainedValue()
                DispatchQueue.main.async { controller.action() }
            }
            return noErr
        }, 1, &eventType, selfPointer, &handlerRef)
        guard status == noErr else { showFailureAlert(); return }

        let id = EventHotKeyID(signature: OSType(UInt32(bigEndian: 0x4B494F4B)), id: 1)
        let modifiers = UInt32(cmdKey | shiftKey)
        let registerStatus = RegisterEventHotKey(UInt32(kVK_ANSI_K), modifiers, id, GetApplicationEventTarget(), 0, &hotKeyRef)
        if registerStatus != noErr { showFailureAlert() }
    }

    private func showFailureAlert() {
        let alert = NSAlert()
        alert.messageText = "Couldn’t register ⌘⇧K. Another app may be using it."
        alert.runModal()
    }

    func unregister() {
        if let hotKeyRef { UnregisterEventHotKey(hotKeyRef) }
        if let handlerRef { RemoveEventHandler(handlerRef) }
        hotKeyRef = nil
        handlerRef = nil
    }
}
