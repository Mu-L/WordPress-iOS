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

    // TODO: (kean)
    public static var shared: BuildSettings {
        fatalError()
//        guard let value = _shared else {
//            fatalError("configuration not registered")
//        }
//        return value
    }

//    private static var _shared: BuildSettings?

    public static func register(_ settings: BuildSettings) {
//        guard _shared == nil else {
//            fatalError("already registered")
//        }
//        _shared = settings
    }
}
