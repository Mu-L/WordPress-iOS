import Foundation

public struct BuildSettings {
    public var itunesAppID: String
    public var pushNotificationAppId: String

    public init(
        itunesAppID: String,
        pushNotificationAppId: String
    ) {
        self.itunesAppID = itunesAppID
        self.pushNotificationAppId = pushNotificationAppId
    }
}
