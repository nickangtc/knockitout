import AppKit

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    private let store = KnockItemStore()
    private let settings = AppSettingsStore()
    private var menuBarController: MenuBarController?
    private var hotKeyController: HotKeyController?
    private var launcherController: LauncherWindowController?
    private var railController: RailWindowController?
    private var toastController: ToastWindowController?
    private var celebrationController: CelebrationWindowController?
    private var welcomeController: WelcomeWindowController?

    func applicationDidFinishLaunching(_ notification: Notification) {
        terminateDuplicateInstanceIfNeeded()
        NSApp.setActivationPolicy(.accessory)
        settings.refreshLaunchAtLogin()
        store.load()

        let launcher = LauncherWindowController(store: store)
        let rail = RailWindowController(store: store)
        let toast = ToastWindowController(store: store)
        let celebration = CelebrationWindowController()
        launcherController = launcher
        railController = rail
        toastController = toast
        celebrationController = celebration

        store.onItemsChanged = { [weak rail, weak toast] in
            rail?.refresh()
            toast?.refresh()
        }
        store.onFinalKnockOut = { [weak celebration] anchor in
            celebration?.show(anchor: anchor)
        }

        let menu = MenuBarController(store: store, settings: settings) { [weak launcher] in launcher?.open() }
        menu.setup()
        menuBarController = menu

        let hotKey = HotKeyController { [weak launcher] in launcher?.open() }
        hotKey.register()
        hotKeyController = hotKey

        rail.refresh()

        if !settings.hasCompletedFirstRunWelcome {
            let welcome = WelcomeWindowController(settings: settings) { [weak launcher] in launcher?.open() }
            welcomeController = welcome
            welcome.show()
        }
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool { false }

    private func terminateDuplicateInstanceIfNeeded() {
        let bundleIdentifier = Bundle.main.bundleIdentifier ?? "com.nickang.knockitout"
        let runningCopies = NSRunningApplication.runningApplications(withBundleIdentifier: bundleIdentifier)
        if runningCopies.contains(where: { $0.processIdentifier != ProcessInfo.processInfo.processIdentifier }) {
            NSApp.terminate(nil)
        }
    }
}
