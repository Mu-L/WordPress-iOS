import Foundation
import UIKit
import SwiftUI
import WordPressUI
import Combine

final class VerifyEmailRow: ImmuTableRow {
    static let cell = ImmuTableCell.class(VerifyEmailCell.self)
    let action: ImmuTableAction? = nil

    func configureCell(_ cell: UITableViewCell) {
        // Do nothing.
    }
}

final class VerifyEmailCell: UITableViewCell {
    private let hostingView: UIHostingView<VerifyEmailView>

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        hostingView = .init(view: .init())
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupView()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupView() {
        selectionStyle = .none
        backgroundColor = .systemRed.withAlphaComponent(0.9)

        contentView.addSubview(hostingView)
        hostingView.pinEdges(to: contentView)
    }
}

private struct VerifyEmailView: View {
    @StateObject private var viewModel = VerifyEmailViewModel()

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(viewModel.state.title)
                .font(.subheadline.weight(.semibold))
                .foregroundColor(.white)

            Text(viewModel.state.message)
                .font(.callout)
                .foregroundColor(.white)

            Spacer()

            if case .sent = viewModel.state {
                HStack(spacing: 4) {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.white)
                    Text(Strings.verificationSent)
                        .font(.callout)
                        .foregroundColor(.white)
                }
                .frame(maxWidth: .infinity, alignment: .center)
            } else {
                HStack {
                    Spacer()

                    Button {
                        viewModel.sendVerificationEmail()
                    } label: {
                        HStack {
                            if viewModel.state.showsActivityIndicator {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle())
                            }

                            Text(viewModel.state.buttonTitle)
                                .foregroundColor(.black)
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(.white)
                        )
                    }
                    .buttonStyle(.plain)
                    .disabled(!viewModel.state.isButtonEnabled)

                    Spacer()
                }
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }
}

// This value is not an actual "timeout" value of the verification link. It's just an arbitrary value to prevent
// users from sending links repeatedly.
private let verificationLinkTimeout: TimeInterval = 300

@MainActor
private class VerifyEmailViewModel: ObservableObject {
    enum State {
        case needsVerification
        case sending
        case sent(Date)
        case error(Error)

        var title: String {
            Strings.title
        }

        var message: String {
            let email = try? WPAccount.lookupDefaultWordPressComAccount(in: ContextManager.shared.mainContext)?.email ?? ""

            switch self {
            case .needsVerification, .sending:
                if let email, !email.isEmpty {
                    return String(format: Strings.verifyMessage, email)
                } else {
                    return Strings.verifyMessageNoEmail
                }

            case .sent:
                if let email, !email.isEmpty {
                    return String(format: Strings.sentMessage, email)
                } else {
                    return Strings.sentMessageNoEmail
                }

            case .error(let error):
                return error.localizedDescription
            }
        }

        var buttonTitle: String {
            switch self {
            case .needsVerification:
                return Strings.sendButton
            case .sending:
                return Strings.sendingButton
            case .sent:
                return Strings.sentButton
            case .error:
                return Strings.retryButton
            }
        }

        var isButtonEnabled: Bool {
            switch self {
            case .needsVerification, .error: return true
            case .sending: return false
            case .sent(let date):
                return Date().timeIntervalSince(date) >= verificationLinkTimeout
            }
        }

        var showsActivityIndicator: Bool {
            if case .sending = self {
                return true
            }
            return false
        }
    }

    private let userID: NSNumber

    private var lastVerificationSentDate: Date? {
        get {
            let key = "LastEmailVerificationSentDate-\(userID)"
            return UserDefaults.standard.object(forKey: key) as? Date
        }
        set {
            let key = "LastEmailVerificationSentDate-\(userID)"
            UserDefaults.standard.set(newValue, forKey: key)
        }
    }

    @Published private(set) var state: State

    init() {
        userID = (try? WPAccount.lookupDefaultWordPressComAccount(in: ContextManager.shared.mainContext)?.userID) ?? 0
        state = .needsVerification

        if let sentDate = lastVerificationSentDate,
           Date().timeIntervalSince(sentDate) < verificationLinkTimeout {
            state = .sent(sentDate)
        }
    }

    func sendVerificationEmail() {
        guard state.isButtonEnabled else { return }

        state = .sending

        let accountService = AccountService(coreDataStack: ContextManager.shared)
        accountService.requestVerificationEmail({ [weak self] in
            Task { @MainActor [weak self] in
                guard let self else { return }
                self.lastVerificationSentDate = Date()
                self.state = .sent(Date())
            }
        }, failure: { [weak self] error in
            Task { @MainActor [weak self] in
                self?.state = .error(error)
            }
        })
    }
}

private enum Strings {
    static let title = NSLocalizedString("me.verifyEmail.title", value: "Verify Your Email", comment: "Title for email verification card")
    static let verifyMessage = NSLocalizedString("me.verifyEmail.message.withEmail", value: "Please verify your email address (%@) to unlock all features.", comment: "Message for email verification card with email address")
    static let verifyMessageNoEmail = NSLocalizedString("me.verifyEmail.message.noEmail", value: "Please verify your email address to unlock all features.", comment: "Message for email verification card")
    static let sentMessage = NSLocalizedString("me.verifyEmail.sent.message.withEmail", value: "We've sent a verification link to %@. Please check your inbox and click the link.", comment: "Message shown after verification link is sent with email address")
    static let sentMessageNoEmail = NSLocalizedString("me.verifyEmail.sent.message.noEmail", value: "We've sent a verification link to your email address. Please check your inbox and click the link.", comment: "Message shown after verification link is sent")
    static let sendButton = NSLocalizedString("me.verifyEmail.button.send", value: "Send Verification Link", comment: "Button title to send verification link")
    static let sendingButton = NSLocalizedString("me.verifyEmail.button.sending", value: "Sending...", comment: "Button title while verification link is being sent")
    static let sentButton = NSLocalizedString("me.verifyEmail.button.sent", value: "Link Sent!", comment: "Button title after verification link is sent")
    static let retryButton = NSLocalizedString("me.verifyEmail.button.retry", value: "Try Again", comment: "Button title when verification link sending failed")
    static let verificationSent = NSLocalizedString("me.verifyEmail.status.sent", value: "Verification link sent", comment: "Message shown when verification link has been sent")
}
