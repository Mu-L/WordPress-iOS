import Foundation
import AutomatticTracks
import WordPressShared
import BuildSettingsKit

@objc public final class AnalyticsTrackerAutomatticTracks: NSObject, WPAnalyticsTracker {
    private let contextManager: TracksContextManager
    private let tracksService: TracksService
    private var userProperties: [String: Any] = [:]
    private var appURLScheme: String
    private var _anonymousID: String?
    private var _loggedInID: String?

    @objc convenience public override init() {
        self.init(
            eventNamePrefix: WPAnalytics.eventNamePrefix,
            platform: WPAnalytics.explatPlatform,
            appURLScheme: BuildSettings.current.appURLScheme
        )
    }

    init(
        eventNamePrefix: String,
        platform: String,
        appURLScheme: String
    ) {
        contextManager = TracksContextManager()
        tracksService = TracksService(contextManager: contextManager)
        tracksService.eventNamePrefix = eventNamePrefix
        tracksService.platform = platform
    }

    // MARK: - WPAnalyticsTracker

    public func track(_ stat: WPAnalyticsStat) {
        track(stat, withProperties: nil)
    }

    public func track(_ stat: WPAnalyticsStat, withProperties properties: [String: Any]?) {
        guard let event = TracksEvent.make(for: stat) else {
            DDLogInfo("WPAnalyticsStat not supported by AnalyticsTrackerAutomatticTracks: \(stat)")
            return
        }

        var mergedProperties = event.properties ?? [:]
        for (key, value) in properties ?? [:] {
            mergedProperties[key] = value
        }
        trackString(event.name, withProperties: mergedProperties)
    }

    public func trackString(_ event: String) {
        trackString(event, withProperties: nil)
    }

    public func trackString(_ event: String, withProperties properties: [String: Any]?) {
        if properties == nil {
            DDLogInfo("🔵 Tracked: \(event)")
        } else {
            let description = Array(properties ?? [:]).sorted {
                $0.key.localizedCaseInsensitiveCompare($1.key) == .orderedAscending
            }.map { key, value in
                "\(key): \(value)"
            }.joined(separator: ", ")
            DDLogInfo("🔵 Tracked: \(event) <\(description)>")
        }
        tracksService.trackEventName(event, withCustomProperties: properties)
    }

    // MARK: - Session Management

    @objc public func beginSession() {
        if let loggedInID, !loggedInID.isEmpty {
            tracksService.switchToAuthenticatedUser(
                withUsername: loggedInID,
                userID: nil,
                wpComToken: try? WPAccount.token(forUsername: loggedInID),
                skipAliasEventCreation: true
            )
        } else {
            tracksService.switchToAnonymousUser(withAnonymousID: anonymousID)
        }
        refreshMetadata()
    }

    @objc public func clearQueuedEvents() {
        tracksService.clearQueuedEvents()
    }

    @objc public func refreshMetadata() {
        let context = ContextManager.sharedInstance().mainContext

        var blogCount: Int = 0
        var username: String?
        var accountPresent = false
        var hasJetpackBlogs = false
        var isGutenbergEnabled = false

        context.performAndWait {
            guard let account = try? WPAccount.lookupDefaultWordPressComAccount(in: context) else {
                return
            }
            blogCount = Blog.count(in: context)
            hasJetpackBlogs = (try? Blog.hasAnyJetpackBlogs(in: context)) == true
            username = account.username
            accountPresent = true
            isGutenbergEnabled = (account.blogs ?? []).contains(where: \.isGutenbergEnabled)
        }

        if let username, UUID(uuidString: username) != nil {
            // User has authenticated but we're waiting for account details to sync.
            // Once details are synced this method will be called again with the actual
            // username. For now just exit without making changes.
            return
        }

        let isDotcomUser = (accountPresent && username?.isEmpty == false)

        var properties: [String: Any] = [:]
        properties["app_scheme"] = WPAnalyticsTesting.appURLScheme ?? appURLScheme
        properties["platform"] = "iOS"
        properties["dotcom_user"] = isDotcomUser
        properties["jetpack_user"] = hasJetpackBlogs
        properties["number_of_blogs"] = blogCount
        properties["accessibility_voice_over_enabled"] = UIAccessibility.isVoiceOverRunning
        properties["is_rtl_language"] = UIApplication.shared.userInterfaceLayoutDirection == .rightToLeft
        properties["gutenberg_enabled"] = isGutenbergEnabled

        tracksService.userProperties.removeAllObjects()
        tracksService.userProperties.addEntries(from: properties)

        // Tell the client what kind of user
        if isDotcomUser, let username {
            if loggedInID?.isEmpty == true {
                // No previous username logged
                loggedInID = username
                removeAnonymousID()

                tracksService.switchToAuthenticatedUser(
                    withUsername: username,
                    userID: "",
                    wpComToken: try? WPAccount.token(forUsername: username),
                    skipAliasEventCreation: false
                )
            } else if loggedInID == username {
                // Username did not change from last refreshMetadata - just make sure Tracks client has it
                tracksService.switchToAuthenticatedUser(
                    withUsername: username,
                    userID: "",
                    wpComToken: try? WPAccount.token(forUsername: username),
                    skipAliasEventCreation: true
                )
            } else {
                // Username changed for some reason - switch back to anonymous first
                tracksService.switchToAnonymousUser(withAnonymousID: anonymousID)
                tracksService.switchToAuthenticatedUser(
                    withUsername: username,
                    userID: "",
                    wpComToken: try? WPAccount.token(forUsername: username),
                    skipAliasEventCreation: false
                )
                loggedInID = username
                removeAnonymousID()
            }
        } else {
            // User is not authenticated, switch to an anonymous mode
            tracksService.switchToAnonymousUser(withAnonymousID: anonymousID)
            loggedInID = nil
        }
    }

    // MARK: - Private

    private var anonymousID: String {
        if _anonymousID == nil || _anonymousID?.isEmpty == true {
            let userDefaults = UserPersistentStoreFactory.instance()
            var anonymousID = userDefaults.string(forKey: Constants.tracksUserDefaultsAnonymousUserIDKey)

            if anonymousID == nil {
                anonymousID = UUID().uuidString
                userDefaults.set(anonymousID, forKey: Constants.tracksUserDefaultsAnonymousUserIDKey)
            }

            _anonymousID = anonymousID
        }

        return _anonymousID!
    }

    private func removeAnonymousID() {
        _anonymousID = nil
        UserPersistentStoreFactory.instance()
            .removeObject(forKey: Constants.tracksUserDefaultsAnonymousUserIDKey)
    }

    private var loggedInID: String? {
        get {
            if _loggedInID == nil || _loggedInID?.isEmpty == true {
                let userDefaults = UserPersistentStoreFactory.instance()
                let loggedInID = userDefaults.string(forKey: Constants.tracksUserDefaultsLoggedInUserIDKey)

                if loggedInID != nil {
                    _loggedInID = loggedInID
                }
            }

            return _loggedInID
        }
        set {
            _loggedInID = newValue

            let userDefaults = UserPersistentStoreFactory.instance()
            if let newValue {
                userDefaults.set(newValue, forKey: Constants.tracksUserDefaultsLoggedInUserIDKey)
            } else {
                userDefaults.removeObject(forKey: Constants.tracksUserDefaultsLoggedInUserIDKey)
            }
        }
    }
}

private enum Constants {
    static let tracksUserDefaultsAnonymousUserIDKey = "TracksAnonymousUserID"
    static let tracksUserDefaultsLoggedInUserIDKey = "TracksLoggedInUserID"
}
