import UIKit

extension BuildSettings {
    static func make(configuration: BuildConfiguration = .current) -> BuildSettings {
        BuildSettings(
            itunesAppID: "335703880",
            pushNotificationAppID: configuration.pushNotificationAppID
        )
    }
}

extension BuildConfiguration {
    var pushNotificationAppID: String {
        switch self {
        case .localDeveloper: "org.wordpress.appstore.dev"
        case .a8cBranchTest: "org.wordpress.alpha"
        case .a8cPrereleaseTesting: "org.wordpress.internal"
        case .appStore: "org.wordpress.appstore"
        }
    }
}
