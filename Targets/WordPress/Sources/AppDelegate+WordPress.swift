import UIKit

class AppDelegate: WordPressAppDelegate {
    override func makeBuildSettings() -> BuildSettings {
        let configuration = XcodeBuildConfiguration.current
        return BuildSettings(
            itunesAppID: "335703880",
            pushNotificationAppID: configuration.pushNotificationAppID
        )
    }
}

private enum XcodeBuildConfiguration {
    case debug
    case `internal`
    case alpha
    case release

#if DEBUG
    static let current: XcodeBuildConfiguration = .debug
#elseif INTERNAL_BUILD
    static let current: XcodeBuildConfiguration = .internal
#elseif ALPHA_BUILD
    static let current: XcodeBuildConfiguration = .current
#else
    static let current: XcodeBuildConfiguration = .release
#endif

    var pushNotificationAppID: String {
        switch self {
        case .debug: "org.wordpress.appstore.dev"
        case .internal: "org.wordpress.internal"
        case .alpha: "org.wordpress.alpha"
        case .release: "org.wordpress.appstore"
        }
    }
}
