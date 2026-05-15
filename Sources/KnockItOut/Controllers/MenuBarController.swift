import AppKit

@MainActor
final class MenuBarController: NSObject, NSMenuDelegate {
    private let store: KnockItemStore
    private let settings: AppSettingsStore
    private let openLauncher: () -> Void
    private var statusItem: NSStatusItem?
    private let launchItem = NSMenuItem(title: "Launch at Login", action: #selector(toggleLaunchAtLogin), keyEquivalent: "")

    init(store: KnockItemStore, settings: AppSettingsStore, openLauncher: @escaping () -> Void) {
        self.store = store
        self.settings = settings
        self.openLauncher = openLauncher
        super.init()
    }

    func setup() {
        let statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        statusItem.button?.image = makeIcon()
        statusItem.button?.image?.isTemplate = true
        let menu = NSMenu()
        menu.delegate = self
        menu.addItem(withTitle: "Open Knock It Out", action: #selector(open), keyEquivalent: "").target = self
        menu.addItem(withTitle: "Clear All Items…", action: #selector(clearAll), keyEquivalent: "").target = self
        menu.addItem(.separator())
        launchItem.target = self
        menu.addItem(launchItem)
        menu.addItem(.separator())
        menu.addItem(withTitle: "About Knock It Out", action: #selector(about), keyEquivalent: "").target = self
        menu.addItem(withTitle: "Quit Knock It Out", action: #selector(quit), keyEquivalent: "q").target = self
        statusItem.menu = menu
        self.statusItem = statusItem
    }

    func menuNeedsUpdate(_ menu: NSMenu) {
        settings.refreshLaunchAtLogin()
        launchItem.state = settings.launchAtLoginEnabled ? .on : .off
    }

    @objc private func open() { openLauncher() }

    @objc private func clearAll() {
        let alert = NSAlert()
        alert.messageText = "Clear all current items"
        alert.addButton(withTitle: "Clear Items")
        alert.addButton(withTitle: "Cancel")
        if alert.runModal() == .alertFirstButtonReturn { store.clearAll() }
    }

    @objc private func toggleLaunchAtLogin() { settings.toggleLaunchAtLogin() }
    @objc private func about() { NSApp.orderFrontStandardAboutPanel(nil) }
    @objc private func quit() { NSApp.terminate(nil) }

    private func makeIcon() -> NSImage {
        let image = NSImage(size: NSSize(width: 18, height: 18))
        image.lockFocus()
        NSColor.white.setFill()
        NSBezierPath(ovalIn: NSRect(x: 1, y: 1, width: 16, height: 16)).fill()
        let attrs: [NSAttributedString.Key: Any] = [.font: NSFont.boldSystemFont(ofSize: 11), .foregroundColor: NSColor.black]
        NSString(string: "K").draw(in: NSRect(x: 5.2, y: 2.7, width: 10, height: 12), withAttributes: attrs)
        image.unlockFocus()
        image.isTemplate = false
        return image
    }
}
