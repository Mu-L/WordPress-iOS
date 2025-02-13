import Foundation
import Gridicons
import UIKit

// MARK: - WordPressAuthenticationManager
//
@objc
class WordPressAuthenticationManager: NSObject {
    static var isPresentingSignIn = false
    private let windowManager: WindowManager

    /// Allows overriding some WordPressAuthenticator delegate methods
    /// without having to reimplement WordPressAuthenticatorDelegate
    private let recentSiteService: RecentSitesService
    private let remoteFeaturesStore: RemoteFeatureFlagStore

    init(windowManager: WindowManager,
         recentSiteService: RecentSitesService = RecentSitesService(),
         remoteFeaturesStore: RemoteFeatureFlagStore) {
        self.windowManager = windowManager
        self.recentSiteService = recentSiteService
        self.remoteFeaturesStore = remoteFeaturesStore
    }

    /// Support is only available to the WordPress iOS App. Our Authentication Framework doesn't have direct access.
    /// We'll setup a mechanism to relay the Support event back to the Authenticator.
    ///
    func startRelayingSupportNotifications() {
        NotificationCenter.default.addObserver(self, selector: #selector(supportPushNotificationReceived), name: .ZendeskPushNotificationReceivedNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(supportPushNotificationCleared), name: .ZendeskPushNotificationClearedNotification, object: nil)
    }

    /// Synchronizes a WordPress.org account with the specified credentials.
    ///
    func syncWPOrg(username: String, password: String, xmlrpc: String, options: [AnyHashable: Any], onCompletion: @escaping () -> ()) {
        let service = BlogSyncFacade()

        service.syncBlog(withUsername: username, password: password, xmlrpc: xmlrpc, options: options) { blog in
            RecentSitesService().touch(blog: blog)
            onCompletion()
        }
    }
}

// MARK: - Initialization Methods
//
extension WordPressAuthenticationManager {
    /// Initializes WordPressAuthenticator with all of the parameters that will be needed during the login flow.
    ///
    func initializeWordPressAuthenticator() {
//        let displayStrings = WordPressAuthenticatorDisplayStrings(
//            continueWithWPButtonTitle: AppConstants.Login.continueButtonTitle
//        )
//
//        WordPressAuthenticator.initialize(configuration: authenticatorConfiguation(),
//                                          style: authenticatorStyle(),
//                                          unifiedStyle: unifiedStyle(),
//                                          displayStrings: displayStrings)
    }


}

// MARK: - Static Methods
//
extension WordPressAuthenticationManager {

    /// Returns an Authentication ViewController (configured to allow only WordPress.com). This method pre-populates the Email + Username
    /// with the values returned by the default WordPress.com account (if any).
    ///
    /// - Parameter onDismissed: Closure to be executed whenever the returned ViewController is dismissed.
    ///
    @objc
    class func signinForWPComFixingAuthToken(_ onDismissed: ((_ cancelled: Bool) -> Void)? = nil) -> UIViewController {
        let context = ContextManager.sharedInstance().mainContext
        let account = try? WPAccount.lookupDefaultWordPressComAccount(in: context)

        // TODO
        return UIViewController()

//        return WordPressAuthenticator.signinForWPCom(dotcomEmailAddress: account?.email, dotcomUsername: account?.username, onDismissed: onDismissed)
    }

    /// Presents the WordPress Authentication UI from the rootViewController (configured to allow only WordPress.com).
    /// This method pre-populates the Email + Username with the values returned by the default WordPress.com account (if any).
    ///
    @objc
    class func showSigninForWPComFixingAuthToken() {
        guard let presenter = UIApplication.shared.mainWindow?.rootViewController else {
            assertionFailure()
            return
        }

        guard !isPresentingSignIn else {
            return
        }

        isPresentingSignIn = true

        let signedInAccount = try? WPAccount.lookupDefaultWordPressComAccount(in: ContextManager.shared.mainContext)
        Task { @MainActor in
            Notice(
                title: NSLocalizedString("wpcom.token.fix.signin", value: "Sign in to WordPress.com", comment: "Message title to be displayed when the user needs to re-authenticate their WordPress.com account."),
                message: NSLocalizedString("wpcom.token.fix.signin.message", value: "You need to sign in to WordPress.com to access your account.", comment: "Detailed message to be displayed when the user needs to re-authenticate their WordPress.com account.")
            ).post()

            let _ = await WordPressDotComAuthenticator().signIn(
                from: presenter,
                context: signedInAccount?.email
                    .flatMap { .reauthentication(accountEmail: $0) }
                    ?? .default
            )

            isPresentingSignIn = false
        }
    }
}

// MARK: - Notification Handlers
//
extension WordPressAuthenticationManager {

    @objc func supportPushNotificationReceived(_ notification: Foundation.Notification) {
        // no-op
    }

    @objc func supportPushNotificationCleared(_ notification: Foundation.Notification) {
        // no-op
    }

}

// MARK: - Blog Count Helpers
private extension WordPressAuthenticationManager {
    private func numberOfBlogs() -> Int {
        let context = ContextManager.sharedInstance().mainContext
        let numberOfBlogs = (try? WPAccount.lookupDefaultWordPressComAccount(in: context))?.blogs?.count ?? 0

        return numberOfBlogs
    }
}

// MARK: - Onboarding Questions Prompt
private extension WordPressAuthenticationManager {
    private func presentEnableNotificationsPrompt(in navigationController: UINavigationController, blog: Blog, onDismiss: (() -> Void)? = nil) {
        let windowManager = self.windowManager

        guard JetpackFeaturesRemovalCoordinator.jetpackFeaturesEnabled(),
              !UserPersistentStoreFactory.instance().onboardingNotificationsPromptDisplayed,
              !UITestConfigurator.isEnabled(.disablePrompts) else {
            if self.windowManager.isShowingFullscreenSignIn {
                self.windowManager.dismissFullscreenSignIn(blogToShow: blog)
            } else {
                self.windowManager.showAppUI(for: blog)
            }
            return
        }

        let onEnableNotificationsCompletion = { [weak navigationController] in
            guard let navigationController else { return }

            if windowManager.isShowingFullscreenSignIn {
                windowManager.dismissFullscreenSignIn(completion: nil)
            } else {
                navigationController.dismiss(animated: true, completion: nil)
            }

            onDismiss?()
        }

        Task { @MainActor in
            let settings = await UNUserNotificationCenter.current().notificationSettings()
            guard settings.authorizationStatus == .notDetermined else {
                onEnableNotificationsCompletion()
                return
            }
            let controller = OnboardingEnableNotificationsViewController(completion: onEnableNotificationsCompletion)
            navigationController.pushViewController(controller, animated: true)
        }
    }
}

// MARK: - WordPressAuthenticatorManager
//
private extension WordPressAuthenticationManager {
    /// Synchronizes a WordPress.com account with the specified credentials.
    ///
    private func syncWPCom(authToken: String, isJetpackLogin: Bool, onCompletion: @escaping () -> ()) {
        let service = WordPressComSyncService()

        // Create a dispatch group to wait for both API calls.
        let syncGroup = DispatchGroup()

        // Sync account and blog
        syncGroup.enter()
        service.syncWPCom(authToken: authToken, isJetpackLogin: isJetpackLogin, onSuccess: { account in

            /// HACK: An alternative notification to LoginFinished. Observe this instead of `WPSigninDidFinishNotification` for Jetpack logins.
            /// When WPTabViewController no longer destroy's and rebuilds the view hierarchy this alternate notification can be removed.
            ///
            let notification: Foundation.Notification.Name = isJetpackLogin == true ? Foundation.Notification.Name("Jetpackloginfinished") : .WPSigninDidFinishNotification
            NotificationCenter.default.post(name: notification, object: account)

            syncGroup.leave()
        }, onFailure: { _ in
            syncGroup.leave()
        })

        // Refresh Remote Feature Flags
        syncGroup.enter()
        WordPressAppDelegate.shared?.updateFeatureFlags(authToken: authToken, completion: {
            syncGroup.leave()
        })

        // Sync done
        syncGroup.notify(queue: .main) {
            onCompletion()
        }
    }
}
