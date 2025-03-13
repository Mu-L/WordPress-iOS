import Foundation

extension BuildSettings {
    /// Returns settings for the given target.
    public static func makeConfiguration(target: BuildTarget, configuration: BuildConfiguration) -> BuildSettings {
        switch target {
        case .wordpress:
            makeWordpressSettings(configuration: configuration)
        case .jetpack:
            makeJetpackSettings(configuration: configuration)
        }
    }
}

// MARK: - Jetpack

private func makeJetpackSettings(configuration: BuildConfiguration) -> BuildSettings {
    BuildSettings(
        itunesAppID: "1565481562",
        pushNotificationAppID: {
            switch configuration {
            case .localDeveloper: "com.jetpack.appstore.dev"
            case .a8cBranchTest: "com.jetpack.alpha"
            case .a8cPrereleaseTesting: "com.jetpack.internal"
            case .appStore: "com.jetpack.appstore"
            }
        }()
    )
}

// MARK: - WordPress

private func makeWordpressSettings(configuration: BuildConfiguration) -> BuildSettings {
    BuildSettings(
        itunesAppID: "335703880",
        pushNotificationAppID: {
            switch configuration {
            case .localDeveloper: "org.wordpress.appstore.dev"
            case .a8cBranchTest: "org.wordpress.alpha"
            case .a8cPrereleaseTesting: "org.wordpress.internal"
            case .appStore: "org.wordpress.appstore"
            }
        }()
    )
}
