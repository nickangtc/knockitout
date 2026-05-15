import Foundation
import ServiceManagement

@MainActor
final class AppSettingsStore: ObservableObject {
    @Published var launchAtLoginEnabled = false

    private let firstRunKey = "hasCompletedFirstRunWelcome"

    var hasCompletedFirstRunWelcome: Bool {
        get { UserDefaults.standard.bool(forKey: firstRunKey) }
        set { UserDefaults.standard.set(newValue, forKey: firstRunKey) }
    }

    func refreshLaunchAtLogin() {
        launchAtLoginEnabled = SMAppService.mainApp.status == .enabled
    }

    func applyLaunchAtLogin(_ enabled: Bool) {
        do {
            if enabled {
                if SMAppService.mainApp.status != .enabled { try SMAppService.mainApp.register() }
            } else {
                if SMAppService.mainApp.status == .enabled { try SMAppService.mainApp.unregister() }
            }
        } catch {
            NSLog("Knock It Out login item error: \(error.localizedDescription)")
        }
        refreshLaunchAtLogin()
    }

    func toggleLaunchAtLogin() {
        applyLaunchAtLogin(!launchAtLoginEnabled)
    }
}
