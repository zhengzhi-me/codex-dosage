import Foundation

enum DiscoveryMode: String { case automatic, manual }

enum ApplicationResolver {
    static let modeKey = "ApplicationDiscoveryMode"
    static func mode(defaults: UserDefaults = .standard) -> DiscoveryMode {
        if let raw = defaults.string(forKey: modeKey), let mode = DiscoveryMode(rawValue: raw) { return mode }
        // Preserve manual choices saved by 0.2.0; new installations default to automatic.
        return defaults.string(forKey: selectionKey) == nil ? .automatic : .manual
    }
    static func containingApplication(_ binary: URL) -> URL? {
        var current = binary.deletingLastPathComponent()
        var found: URL?
        while current.path != "/" {
            if current.pathExtension == "app" { found = current }
            current.deleteLastPathComponent()
        }
        return found
    }
    static let selectionKey = "SelectedApplicationPath"
    static let candidates = ["Contents/Resources/codex-cli/bin/codex", "Contents/Resources/codex", "Contents/Resources/codex-cli/CodexCLI.app/Contents/MacOS/codex"]

    static func binary(in app: URL) throws -> URL {
        guard app.pathExtension.lowercased() == "app", Bundle(url: app) != nil else { throw FetchError.invalidApplication }
        for relative in candidates {
            let url = app.appendingPathComponent(relative)
            if FileManager.default.isExecutableFile(atPath: url.path) { return url }
        }
        throw FetchError.codexNotFound(app.path)
    }

    static func resolve() throws -> URL {
        if let override = ProcessInfo.processInfo.environment["CODEX_BIN"] {
            guard FileManager.default.isExecutableFile(atPath: override) else { throw FetchError.codexNotFound(override) }
            return URL(fileURLWithPath: override)
        }
        if mode() == .manual {
            guard let selected = UserDefaults.standard.string(forKey: selectionKey) else { throw FetchError.applicationNotSelected }
            return try binary(in: URL(fileURLWithPath: selected))
        }
        let roots = [URL(fileURLWithPath: "/Applications"), FileManager.default.homeDirectoryForCurrentUser.appendingPathComponent("Applications")]
        for root in roots {
            let apps = (try? FileManager.default.contentsOfDirectory(at: root, includingPropertiesForKeys: nil)) ?? []
            for app in apps.sorted(by: { $0.path < $1.path }) where Bundle(url: app)?.bundleIdentifier == "com.openai.codex" {
                if let binary = try? binary(in: app) { return binary }
            }
        }
        throw FetchError.codexNotFound(L.text("请选择 ChatGPT 或 Codex 应用", "Select a ChatGPT or Codex application"))
    }
}
