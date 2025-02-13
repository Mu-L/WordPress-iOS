import SwiftUI
import AuthenticationServices

@available(iOS 16.4, *)
public struct WordPressLoginView: View {

    @Environment(\.sizeCategory)
    private var sizeCategory

    @Environment(\.colorScheme)
    private var colorScheme

    @Environment(\.webAuthenticationSession)
    private var webAuthenticationSession

    @Environment(\.selfHostedSiteAuthenticator)
    private var selfHostedClient: SelfHostedSiteAuthenticator

    @Environment(\.dotComAuthenticator)
    private var dotComClient: WordPressDotComAuthenticator

    @State
    private var isShowingButtonSheet = false

    @State
    private var isLoggingIn = false

    public init() {}

    public var body: some View {
        VStack(spacing: 0) {
            SplashPrologueView()

            Group {
                if sizeCategory > .accessibilityMedium {
                    LoginButton(text: "Get Started") {
                        self.isShowingButtonSheet = true
                    }.padding(.top)
                } else {
                    loginButtons.padding(.top)
                }
            }.background(Color(UIColor(light: .white, dark: .black)))
        }
        .sheet(isPresented: $isShowingButtonSheet) {
            if #available(iOS 16.4, *) {
                loginButtons
                .presentationBackground(.gray)
                .presentationDetents([.fraction(0.25)])
            } else {
                loginButtons
                .presentationDetents([.medium])
            }
        }
        .overlay {
            if isLoggingIn {
                ZStack {
                    ProgressView().controlSize(.large)
                    if colorScheme == .dark {
                        Color.gray.opacity(0.7).ignoresSafeArea()
                    } else {
                        Color.black.opacity(0.7).ignoresSafeArea()
                    }
                 }
            }
        }
    }

    @ViewBuilder
    var loginButtons: some View {
        VStack(alignment: .leading, spacing: 16) {
            LoginButton(
                text: "Log in or sign up with WordPress.com",
                action: loginToWpCom
            )

            NavigationLink {
                LoginWithUrlView { credentials in
                    Task {
                        do {
                            self.isLoggingIn = true

                            defer {
                                self.isLoggingIn = false
                            }

                            try await selfHostedClient.login(with: credentials)
                        } catch {
                            debugPrint(error.localizedDescription)
                        }
                    }
                }
            } label: {
                LoginButtonText(text: "Enter your existing site address")
            }
            .controlSize(.large)
            .buttonStyle(.bordered)
            .padding(.horizontal)
            .accentColor(.primary)
        }
    }

    private func loginToWpCom() {
        Task {
            do {
                let url = try await webAuthenticationSession.authenticate(
                    using: dotComClient.wpComAuthenticationURL,
                    callbackURLScheme: "x-wordpress-app"
                )

                // We start the login indicator after we have the user's token
                // to show that something is going on while the sync happens
                // in the background
                self.isLoggingIn = true
                defer {
                    self.isLoggingIn = false
                }

                try await dotComClient.loginUsing(callbackUrl: url)
            } catch {
                debugPrint(error.localizedDescription)
            }
        }
    }
}

#Preview {
    if #available(iOS 16.4, *) {
        WordPressLoginView()
    }
}
