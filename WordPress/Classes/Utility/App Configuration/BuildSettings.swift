import Foundation

public struct BuildSettings: Sendable {
    public var itunesAppID: String
    public var pushNotificationAppID: String

    public init(
        itunesAppID: String,
        pushNotificationAppID: String
    ) {
        self.itunesAppID = itunesAppID
        self.pushNotificationAppID = pushNotificationAppID
    }

    static var current: BuildSettings {
        guard let value = _current else {
            fatalError("configuration not registered")
        }
        return value
    }

    private static var _current: BuildSettings?

    static func register(_ settings: BuildSettings) {
        guard _current == nil else {
            fatalError("already registered")
        }
        _current = settings
    }
}
