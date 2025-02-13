import Foundation
import WordPressAPI
import AutomatticTracks
import SwiftUI
import AuthenticationServices
import WordPressKit

// MARK: - WordPress.org (aka self-hosted site) Credentials
//
public struct WordPressOrgCredentials: Equatable {
    /// Self-hosted login username.
    /// The one used in the /wp-admin/ panel.
    ///
    public let username: String

    /// Self-hosted login password.
    /// The one used in the /wp-admin/ panel.
    ///
    public let password: String

    /// The URL to reach the XMLRPC file.
    /// e.g.: https://exmaple.com/xmlrpc.php
    ///
    public let xmlrpc: String

    /// Self-hosted site options
    ///
    public let options: [AnyHashable: Any]

    /// Designated initializer
    ///
    public init(username: String, password: String, xmlrpc: String, options: [AnyHashable: Any]) {
        self.username = username
        self.password = password
        self.xmlrpc = xmlrpc
        self.options = options
    }

    /// Returns site URL by stripping "/xmlrpc.php" from `xmlrpc` String property
    ///
    public var siteURL: String {
        xmlrpc.removingSuffix("/xmlrpc.php")
    }
}

extension Foundation.Notification.Name {
    static let WPSigninDidFinishNotification = Foundation.Notification.Name("WPSigninDidFinishNotification")
    static let JPSigninDidFinishNotification = Foundation.Notification.Name("wordpressLoginFinishedJetpackLogin")
}

import Foundation

// MARK: - WordPress.com Credentials
//
public struct WordPressComCredentials: Equatable {

    /// WordPress.com authentication token
    ///
    public let authToken: String

    /// Is this a Jetpack-connected site?
    ///
    public let isJetpackLogin: Bool

    /// Is 2-factor Authentication Enabled?
    ///
    public let multifactor: Bool

    /// The site address used during login
    ///
    public var siteURL: String

    private let wpComURL = "https://wordpress.com"

    /// Legacy  initializer, for backwards compatibility
    ///
    public init(authToken: String,
                isJetpackLogin: Bool,
                multifactor: Bool,
                siteURL: String = "https://wordpress.com") {
        self.authToken = authToken
        self.isJetpackLogin = isJetpackLogin
        self.multifactor = multifactor
        self.siteURL = !siteURL.isEmpty ? siteURL : wpComURL
    }
}

// MARK: - Equatable Conformance
//
public func ==(lhs: WordPressComCredentials, rhs: WordPressComCredentials) -> Bool {
    return lhs.authToken == rhs.authToken && lhs.siteURL == rhs.siteURL
}

// MARK: - Authenticator Credentials
//
public struct AuthenticatorCredentials {
    /// WordPress.com credentials
    ///
    public let wpcom: WordPressComCredentials?

    /// Self-hosted site credentials
    ///
    public let wporg: WordPressOrgCredentials?

    /// Designated initializer
    ///
    public init(wpcom: WordPressComCredentials? = nil, wporg: WordPressOrgCredentials? = nil) {
        self.wpcom = wpcom
        self.wporg = wporg
    }
}


// MARK: - Equatable Conformance
//
public func ==(lhs: WordPressOrgCredentials, rhs: WordPressOrgCredentials) -> Bool {
    return lhs.username == rhs.username && lhs.password == rhs.password && lhs.xmlrpc == rhs.xmlrpc
}

final actor SelfHostedSiteAuthenticator {

    enum SignInError: Error {
        case authentication(WordPressLoginClientError)
        case loadingSiteInfoFailure
        case savingSiteFailure
    }

    private let internalClient: WordPressLoginClient

    init(session: URLSession) {
        self.internalClient = WordPressLoginClient(urlSession: session)
    }

    private func trackSuccess(url: String) {
        WPAnalytics.track(.applicationPasswordLogin, properties: [
            "url": url,
            "success": true
        ])
    }

    private func trackTypedError(_ error: SelfHostedSiteAuthenticator.SignInError, url: String) {
        DDLogError("Unable to login to \(url): \(error.localizedDescription)")

        WPAnalytics.track(.applicationPasswordLogin, properties: [
            "url": url,
            "success": false,
            "error": error.localizedDescription
        ])
    }

    @MainActor
    func signIn(site: String, from anchor: ASPresentationAnchor?) async throws(SignInError) -> WordPressOrgCredentials {
        do {
            let result = try await _signIn(site: site, from: anchor)
            await trackSuccess(url: site)
            return result
        } catch {
            await trackTypedError(error, url: site)
            throw error
        }
    }

    @MainActor
    private func _signIn(site: String, from anchor: ASPresentationAnchor?) async throws(SignInError) -> WordPressOrgCredentials {
        let success: WpApiApplicationPasswordDetails
        do {
            success = try await authentication(site: site, from: anchor)
        } catch {
            throw .authentication(error)
        }

        return try await handleSuccess(success)
    }

    @MainActor
    func authentication(site: String, from anchor: ASPresentationAnchor?) async throws(WordPressLoginClientError) -> WpApiApplicationPasswordDetails {
        let appId: WpUuid
        let appName: String

        if AppConfiguration.isJetpack {
            appId = try! WpUuid.parse(input: "7088f42d-34e9-4402-ab50-b506b819f3e4")
            appName = "Jetpack iOS"
        } else {
            appId = try! WpUuid.parse(input: "a9cb72ed-311b-4f01-a0ac-a7af563d103e")
            appName = "WordPress iOS"
        }

        let deviceName = UIDevice.current.name
        let timestamp = ISO8601DateFormatter.string(from: .now, timeZone: .current, formatOptions: .withInternetDateTime)
        let appNameValue = "\(appName) - \(deviceName) (\(timestamp))"

        return try await internalClient.login(
            site: site,
            appName: appNameValue,
            appId: appId
        )
    }

    @MainActor
    func pushLoginScreen(from viewController: UIViewController, onCompletion: @escaping (WordPressOrgCredentials) -> Void) {
        let viewController = buildLoginViewController(presentedFrom: viewController, onCompletion: onCompletion)
        viewController.navigationController?.pushViewController(viewController, animated: true)
    }

    @MainActor
    func presentLoginScreenOverlay(from viewController: UIViewController, onCompletion: @escaping (WordPressOrgCredentials) -> Void) {
        let navigationVC = UINavigationController(rootViewController: buildLoginViewController(presentedFrom: viewController, onCompletion: onCompletion))
        navigationVC.modalPresentationStyle = .formSheet
        viewController.present(navigationVC, animated: true)
    }

    @MainActor @discardableResult
    func login(with credentials: WordPressOrgCredentials) async throws -> WordPressOrgCredentials{
        let credentials = try await self.handleSuccess(WpApiApplicationPasswordDetails(
            siteUrl: credentials.siteURL,
            userLogin: credentials.username,
            password: credentials.password
        ))

        NotificationCenter.default.post(name: .WPSigninDidFinishNotification, object: nil)

        return credentials
    }

    @MainActor
    private func buildLoginViewController(
        presentedFrom viewController: UIViewController,
        onCompletion: @escaping (WordPressOrgCredentials) -> Void
    ) -> UIViewController {
        let loginView = LoginWithUrlView(loginCompleted: { credentials in
            guard let window = viewController.navigationController?.navigationBar.window else {
                preconditionFailure("We hit a bad bug")
            }

            let windowManager = AppDependency.windowManager(window: window)
            let authManager = AppDependency.authenticationManager(windowManager: windowManager)

            authManager.syncWPOrg(username: credentials.username, password: credentials.password, xmlrpc: credentials.xmlrpc, options: [:]) {
                NotificationCenter.default.post(name: .WPSigninDidFinishNotification, object: nil)
            }
        })
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button(SharedStrings.Button.cancel) { [weak viewController] in
                    viewController?.dismiss(animated: true)
                }
            }
        }

        return UIHostingController(rootView: loginView)
    }

    private func handleSuccess(_ success: WpApiApplicationPasswordDetails) async throws(SignInError) -> WordPressOrgCredentials {
        let xmlrpc: String
        let blogOptions: [AnyHashable: Any]
        do {
            xmlrpc = try success.derivedXMLRPCRoot.absoluteString
            blogOptions = try await loadSiteOptions(details: success)
        } catch {
            throw .loadingSiteInfoFailure
        }

        // Only store the new site after credentials are validated.
        do {
            let _ = try await Blog.createRestApiBlog(with: success, in: ContextManager.shared)
        } catch {
            throw .savingSiteFailure
        }

        let wporg = WordPressOrgCredentials(
            username: success.userLogin,
            password: success.password,
            xmlrpc: xmlrpc,
            options: blogOptions
        )
        return wporg
    }

    private func loadSiteOptions(details: WpApiApplicationPasswordDetails) async throws -> [AnyHashable: Any] {
        let xmlrpc = try details.derivedXMLRPCRoot
        return try await withCheckedThrowingContinuation { continuation in

//            WordPressOrgXMLRPCApi *api = [[WordPressOrgXMLRPCApi alloc] initWithEndpoint:xmlrpc userAgent:self.userAgent];
//            [api checkCredentials:username password:password success:^(id responseObject, NSHTTPURLResponse *httpResponse __unused) {
//                dispatch_async(dispatch_get_main_queue(), ^{
//                    if (![responseObject isKindOfClass:[NSDictionary class]]) {
//                        if (failure) {
//                            NSDictionary *userInfo = @{NSLocalizedDescriptionKey: NSLocalizedString(@"Unable to read the WordPress site at that URL. Tap 'Need more help?' to view the FAQ.", nil)};
//                            NSError *error = [NSError errorWithDomain:WordPressOrgXMLRPCApiErrorDomain code:WordPressOrgXMLRPCApiErrorResponseSerializationFailed userInfo:userInfo];
//                            failure(error);
//                        }
//                        return;
//                    }
//                    if (success) {
//                        success((NSDictionary *)responseObject);
//                    }
//                });
//
//            } failure:^(NSError *error, NSHTTPURLResponse *httpResponse __unused) {
//                dispatch_async(dispatch_get_main_queue(), ^{
//                    if (failure) {
//                        failure(error);
//                    }
//                });
//            }];

            let api = WordPressOrgXMLRPCApi(endpoint: xmlrpc, userAgent: WPUserAgent.defaultUserAgent())
            api.checkCredentials(details.userLogin, password: details.password) { dictionary, response in
                if let dictionary = dictionary as? [AnyHashable: Any] {
                    continuation.resume(returning: dictionary)
                } else {
                    continuation.resume(throwing: CocoaError.error(.coderInvalidValue))
                }
            } failure: { error, httpResponse in
                continuation.resume(throwing: error)
            }
        }
    }
}

// Allow injecting `SelfHostedSiteAuthenticator` into SwiftUI Views
extension EnvironmentValues {
    @Entry
    var selfHostedSiteAuthenticator: SelfHostedSiteAuthenticator = SelfHostedSiteAuthenticator(session: .shared)
}
