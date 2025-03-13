import Foundation
import PackagePlugin

@main
struct BuildSettingsGenPlugin: BuildToolPlugin {
    func createBuildCommands(context: PluginContext, target: Target) async throws -> [Command] {
        fatalError("unsupported")
    }
}

#if canImport(XcodeProjectPlugin)
import XcodeProjectPlugin

extension BuildSettingsGenPlugin: XcodeBuildToolPlugin {

    /// 👇 This entry point is called when operating on an Xcode project.
    func createBuildCommands(context: XcodePluginContext, target: XcodeTarget) throws -> [Command] {
        print("\n-----\nContext:")
        print(context.xcodeProject.displayName)

        print("\n-----\nTarget:")
        print(target.displayName)

        print("\n-----\nEnvironment:")
        print(ProcessInfo.processInfo.environment)

        let outputPath = context.pluginWorkDirectoryURL

        print("\n-----\nOutput Path: \(outputPath)")

        return [
            .buildCommand(
                displayName: "Generate Build Configuration",
                executable: try context.tool(named: "BuildSettingsGen").url,
                arguments: ["--output-path", context.pluginWorkDirectoryURL.absoluteString],
                environment: [:]
            )
        ]
    }
}
#endif
