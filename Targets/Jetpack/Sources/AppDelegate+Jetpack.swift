import UIKit

class AppDelegate: WordPressAppDelegate {
    override func makeBuildSettings() -> BuildSettings {
        let configuration = XcodeBuildConfiguration.current
        return BuildSettings(
            itunesAppID: "1565481562",
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
        case .debug: "com.jetpack.appstore.dev"
        case .internal: "com.jetpack.internal"
        case .alpha: "com.jetpack.alpha"
        case .release: "com.jetpack.appstore"
        }
    }
}
