import UIKit
import BuildSettings

extension BuildSettings {
    static func make(configuration: BuildConfiguration = .current) -> BuildSettings {
        BuildSettings(
            itunesAppID: "1565481562",
            pushNotificationAppID: configuration.pushNotificationAppID
        )
    }
}

extension BuildConfiguration {
    var pushNotificationAppID: String {
        switch self {
        case .localDeveloper: "com.jetpack.appstore.dev"
        case .a8cBranchTest: "com.jetpack.alpha"
        case .a8cPrereleaseTesting: "com.jetpack.internal"
        case .appStore: "com.jetpack.appstore"
        }
    }
}
