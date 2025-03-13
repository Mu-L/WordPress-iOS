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
    func createBuildCommands(context: XcodePluginContext, target: XcodeTarget) throws -> [Command] {
        let outputDirectoryURL = context.pluginWorkDirectoryURL
        return [
            .buildCommand(
                displayName: "Generate Build Configuration",
                executable: try context.tool(named: "BuildSettingsGen").url,
                arguments: ["--output-path", outputDirectoryURL.absoluteString],
                environment: [:],
                outputFiles: [outputDirectoryURL.appendingPathComponent("BuildSettings.plist")]
            )
        ]
    }
}
#endif
