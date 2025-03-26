import UIKit

class TestingAppDelegate: NSObject, UIApplicationDelegate {

    var window: UIWindow?

    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil
    ) -> Bool {
        let window = UIWindow(frame: UIScreen.main.bounds)

        let storyboard = UIStoryboard(name: "TestingMode", bundle: Bundle(for: type(of: self)))
        window.rootViewController = storyboard.instantiateInitialViewController()
        window.makeKeyAndVisible()

        self.window = window
        return true
    }
}
