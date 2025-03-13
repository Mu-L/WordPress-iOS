import Foundation
import ArgumentParser
import BuildSettings

@main
struct BuildSettingsGen: ParsableCommand {
    @Option(help: "The path where the generated configuration will be created")
    var outputPath: String

    func run() throws {
        guard let outputDirectoryURL = URL(string: outputPath) else {
            throw BuildSettingsGenError.invalidOutputPath
        }

        let environment = ProcessInfo.processInfo.environment

        func getEnvironmentValue(named name: String) throws -> String {
            guard let value = environment[name] else {
                throw BuildSettingsGenError.missingEnvironmentVariable(name)
            }
            return value
        }

        let target: BuildTarget = try {
            let target = try getEnvironmentValue(named: "TARGET_NAME")
            switch target {
            case "JetpackBuildSettingsGen": return .jetpack
            case "WordPressBuildSettingsGen": return .wordpress
            default: throw BuildSettingsGenError.invalidTarget(target)
            }
        }()

        // jpdebug, jetpack jpalpha (User-Defined WPCOM_SCHEME environment variable)
        // let scheme = environment["WPCOM_SCHEME"]!

        // Path to Info.plist. Example: /Users/kean/Developer/WordPress-iOS/WordPress/Jetpack/Info.plist
        // let plistPath = environment["PRODUCT_SETTINGS_PATH"]!

        // "CONFIGURATION_BUILD_DIR": "/Users/kean/Library/Developer/Xcode/DerivedData/WordPress-cbrxooevkpbmkqcydpgqdjklzpvn/Build/Products/Debug-iphonesimulator"
        // let buildDir = environment["CONFIGURATION_BUILD_DIR"]!

        // TODO: (kean) configuration missing
        let settings = makeConfiguration(target: target, configuration: .localDeveloper)

        let encoder = PropertyListEncoder()
        encoder.outputFormat = .xml
        let data = try encoder.encode(settings)
        try data.write(to: outputDirectoryURL.appendingPathComponent("BuildSettings.plist"))
    }
}

private enum BuildSettingsGenError: Error {
    case invalidOutputPath
    case missingEnvironmentVariable(String)
    case invalidTarget(String)
}

enum BuildTarget: String {
    /// WordPress app or one of its extensions.
    case wordpress

    /// Jetpack app or one of its extensions.
    case jetpack
}

enum BuildConfiguration: String {
    /// Development build, usually run from Xcode
    case localDeveloper

    /// Continuous integration builds for Automattic employees to test branches & PRs
    case a8cBranchTest

    /// Beta released internally for Automattic employees
    case a8cPrereleaseTesting

    /// Production build released in the app store
    case appStore
}

private func makeConfiguration(target: BuildTarget, configuration: BuildConfiguration) -> BuildSettings {
    switch target {
    case .wordpress:
        makeWordpressSettings(configuration: configuration)
    case .jetpack:
        makeJetpackSettings(configuration: configuration)
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
