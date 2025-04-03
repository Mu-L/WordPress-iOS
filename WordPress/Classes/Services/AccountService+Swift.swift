import Foundation
import WordPressShared
import ShareExtensionCore
import WebKit

extension AccountService {

    @objc public static let defaultDotcomAccountUUIDDefaultsKey = "AccountDefaultDotcomUUID"

    func removeDefaultWordPressComAccount() {
        wpAssert(Thread.isMainThread, "This method should only be called from the main thread")

        PushNotificationsManager.shared.unregisterDeviceToken()

        guard let account = try? WPAccount.lookupDefaultWordPressComAccount(in: coreDataStack.mainContext) else {
            return
        }

        let objectID = TaggedManagedObjectID(account)
        coreDataStack.performAndSave { context in
            do {
                let account = try context.existingObject(with: objectID)
                context.delete(account)
            } catch {
                wpAssertionFailure("account missing")
            }
        }

        // Clear WordPress.com cookies
        let cookieJars: [CookieJar] = [
            HTTPCookieStorage.shared,
            WKWebsiteDataStore.default().httpCookieStore
        ]

        for cookieJar in cookieJars {
            cookieJar.removeWordPressComCookies(completion: {})
        }

        URLCache.shared.removeAllCachedResponses()

        // Remove defaults
        UserPersistentStoreFactory.instance().removeObject(forKey: AccountService.defaultDotcomAccountUUIDDefaultsKey)

        WPAnalytics.refreshMetadata()
        NotificationCenter.default.post(name: .WPAccountDefaultWordPressComAccountChanged, object: nil)

        StatsCache.clearCaches()
    }

    func setupAppExtensions() {
        let context = coreDataStack.mainContext
        context.performAndWait {
            guard let account = try? WPAccount.lookupDefaultWordPressComAccount(in: context) else {
                return
            }
            self.setupAppExtensions(defaultAccount: account)
        }
    }

    @objc func setupAppExtensions(defaultAccount: WPAccount) {
        let shareExtensionService = ShareExtensionService()
        let notificationSupportService = NotificationSupportService()

        guard let defaultBlog = defaultAccount.defaultBlog, !defaultBlog.isDeleted else {
            DispatchQueue.main.async {
                shareExtensionService.removeShareExtensionConfiguration()
                notificationSupportService.deleteServiceExtensionToken()
            }
            return
        }

        let defaultAccountObjectID = TaggedManagedObjectID(defaultAccount)
        let siteID = defaultBlog.dotComID?.intValue
        let siteName = defaultBlog.settings?.name

        DispatchQueue.main.async {
            do {
                let defaultAccount = try self.coreDataStack.mainContext.existingObject(with: defaultAccountObjectID)

                if let siteID, let siteName {
                    shareExtensionService.storeDefaultSiteID(siteID, defaultSiteName: siteName)
                } else {
                    wpAssertionFailure("siteID and/or siteName missing")
                }

                if let authToken = defaultAccount.authToken {
                    shareExtensionService.storeToken(authToken)
                    notificationSupportService.storeToken(authToken)
                } else {
                    wpAssertionFailure("authToken missing")
                }

                shareExtensionService.storeUsername(defaultAccount.username)
                notificationSupportService.storeUsername(defaultAccount.username)

                if let userID = defaultAccount.userID?.stringValue {
                    notificationSupportService.storeUserID(userID)
                } else {
                    wpAssertionFailure("userID missing")
                }
            } catch {
                wpAssertionFailure("failed to fetch the default account")
            }
        }
    }

    /// Loads the default WordPress account's cookies into shared cookie storage.
    ///
    static func loadDefaultAccountCookies() {
        guard
            let account = try? WPAccount.lookupDefaultWordPressComAccount(in: ContextManager.shared.mainContext),
            let auth = RequestAuthenticator(account: account),
            let url = URL(string: WPComDomain)
        else {
            return
        }
        auth.request(url: url, cookieJar: HTTPCookieStorage.shared) { _ in
            // no op
        }
    }

}
