import Foundation

enum PersistencePaths {
    static var appSupportDirectory: URL {
        let base = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        return base.appendingPathComponent("Knock It Out", isDirectory: true)
    }

    static var itemsURL: URL {
        appSupportDirectory.appendingPathComponent("items.json")
    }

    static var appearanceURL: URL {
        appSupportDirectory.appendingPathComponent("appearance.json")
    }

    static func ensureDirectory() throws {
        try FileManager.default.createDirectory(at: appSupportDirectory, withIntermediateDirectories: true)
    }
}
