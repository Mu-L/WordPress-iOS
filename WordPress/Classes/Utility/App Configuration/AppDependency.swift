import Foundation

/// - Warning:
/// This configuration class has a **Jetpack** counterpart in the Jetpack bundle.
/// Make sure to keep them in sync to avoid build errors when building the Jetpack target.
struct AppDependency {
    static func authenticationManager(windowManager: WindowManager) -> WordPressAuthenticationManager {
        WordPressAuthenticationManager(
            windowManager: windowManager,
            remoteFeaturesStore: RemoteFeatureFlagStore()
        )
    }

    static func windowManager(window: UIWindow) -> WindowManager {
        return WindowManager(window: window)
    }

    static let dotComAuthenticator = WordPressDotComAuthenticator()
}
