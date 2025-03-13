import Foundation

public struct BuildSettings: Sendable, Codable {
    public var itunesAppID: String
    public var pushNotificationAppID: String

    public init(
        itunesAppID: String,
        pushNotificationAppID: String
    ) {
        self.itunesAppID = itunesAppID
        self.pushNotificationAppID = pushNotificationAppID
    }

    public static let shared: BuildSettings = {
        if let cachedSettings {
            return cachedSettings
        }
        let settings = getBuildSettings()
        cachedSettings = settings
        return settings
    }()

    nonisolated(unsafe) private static var cachedSettings: BuildSettings?

    private static func getBuildSettings() -> BuildSettings {
        guard let settingsURL = Bundle.main.url(forResource: "BuildSettings", withExtension: "plist") else {
            fatalError("BuildSettings.plist is missing")
        }
        do {
            let data = try Data(contentsOf: settingsURL)
            return try PropertyListDecoder().decode(BuildSettings.self, from: data)
        } catch {
            fatalError("BuildSettings.plist invalid: \(error)")
        }
    }

    // TODO: (kean) remove
    public static func register(_ settings: BuildSettings) {
//        guard _shared == nil else {
//            fatalError("already registered")
//        }
//        _shared = settings
    }
}

public enum BuildTarget: String {
    /// WordPress app.
    case wordpress

    /// Jetpack app.
    case jetpack
}

public enum BuildConfiguration: String {
    /// Development build, usually run from Xcode
    case localDeveloper

    /// Continuous integration builds for Automattic employees to test branches & PRs
    case a8cBranchTest

    /// Beta released internally for Automattic employees
    case a8cPrereleaseTesting

    /// Production build released in the app store
    case appStore
}
