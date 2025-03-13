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
        print(environment)

        // jpdebug, jetpack jpalpha (User-Defined WPCOM_SCHEME environment variable)
        let scheme = environment["WPCOM_SCHEME"]!

        // Path to Info.plist. Example: /Users/kean/Developer/WordPress-iOS/WordPress/Jetpack/Info.plist
        let plistPath = environment["PRODUCT_SETTINGS_PATH"]!

        // "CONFIGURATION_BUILD_DIR": "/Users/kean/Library/Developer/Xcode/DerivedData/WordPress-cbrxooevkpbmkqcydpgqdjklzpvn/Build/Products/Debug-iphonesimulator"
        let buildDir = environment["CONFIGURATION_BUILD_DIR"]!

        // Example: "Jetpack"
        let target = environment["TARGET_NAME"]!

        print(scheme, plistPath, buildDir, target)

        let settings = BuildSettings(
            itunesAppID: "testItunesID",
            pushNotificationAppID: "testPushID"
        )

        let encoder = PropertyListEncoder()
        encoder.outputFormat = .xml
        let data = try encoder.encode(settings)
        try data.write(to: outputDirectoryURL.appendingPathComponent("BuildSettings.plist"))
    }
}

private enum BuildSettingsGenError: Error {
    case invalidOutputPath
}
