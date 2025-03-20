import SwiftUI
import DesignSystem
import WordPressUI

protocol NoSitesViewDelegate: AnyObject {
    func didTapAccountAndSettingsButton()
}

struct NoSitesView: View {
    @ObservedObject var account: WPAccount

    let appUIType: RootViewCoordinator.AppUIType?
    let onSelection: (AddSiteMenuViewModel.Selection) -> Void
    weak var delegate: NoSitesViewDelegate?

    @Environment(\.horizontalSizeClass) var horizontalSizeClass

    var body: some View {
        ZStack {
            VStack {
                emptyStateView
                    .frame(maxHeight: .infinity, alignment: .center)

                if account.verificationStatus != .verified {
                    Group {
                        VerifyEmailView(fillVerticalSpace: false)
                            .background(
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(.white)
                            )
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .padding(.horizontal, .DS.Padding.medium)
                    .padding(.bottom, .DS.Padding.medium)
                }

                let viewModel = NoSitesViewModel(appUIType: appUIType, account: account)
                if viewModel.isShowingAccountAndSettings, horizontalSizeClass == .compact {
                    accountAndSettingsButton(viewModel: viewModel)
                        .padding(.horizontal, .DS.Padding.large)
                        .padding(.bottom, .DS.Padding.medium)
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var emptyStateView: some View {
        EmptyStateView {
            Label(Strings.title, image: "noSitesEmptyStateImage")
        } description: {
            Text(Strings.description)
        } actions: {
            VStack(spacing: 20) {
                let actions = AddSiteMenuViewModel(onSelection: onSelection).actions
                ForEach(actions, id: \.id) { action in
                    let button = Button(action.title) {
                            WPAnalytics.track(.mySiteNoSitesViewActionTapped)
                            action.handler()
                        }
                    if action.id == actions.first?.id {
                        button.buttonStyle(.primary)
                    } else {
                        button
                    }
                }
            }
        }
    }

    private func accountAndSettingsButton(viewModel: NoSitesViewModel) -> some View {
        Button {
            delegate?.didTapAccountAndSettingsButton()
        } label: {
            HStack(alignment: .center, spacing: .DS.Padding.double) {
                makeGravatarIcon(size: 40, viewModel: viewModel)
                accountAndSettingsStackView(viewModel: viewModel)
                Spacer()
                Image(systemName: "chevron.forward")
                    .tint(.secondary)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(Color(uiColor: .secondarySystemGroupedBackground))
            .cornerRadius(10)
        }
    }

    private func accountAndSettingsStackView(viewModel: NoSitesViewModel) -> some View {
        VStack(alignment: .leading) {
            Text(viewModel.displayName)
                .foregroundColor(.primary)
                .font(.callout.weight(.semibold))
                .lineLimit(1)
                .minimumScaleFactor(0.5)
            Text(Strings.accountAndSettings)
                .foregroundColor(.secondary)
                .font(.subheadline.weight(.regular))
                .lineLimit(1)
                .minimumScaleFactor(0.5)
        }
    }

    private func makeGravatarIcon(size: CGFloat, viewModel: NoSitesViewModel) -> some View {
        AsyncImage(url: viewModel.gravatarURL) { phase in
            switch phase {
            case .success(let image):
                image.resizable()
                    .scaledToFill()
                    .frame(width: size, height: size)
                    .clipShape(Circle())
            default:
                Image(uiImage: .gridicon(.userCircle, size: CGSize(width: size, height: size)))
                    .tint(.secondary)
            }
        }
    }
}

private enum Strings {
    static let title = NSLocalizedString("mySite.noSites.stateViewTitle", value: "Create Your First Site", comment: "Title description for when a user has no sites.")
    static let description = NSLocalizedString("mySite.noSites.description", value: "Create a new site for your business, magazine, or personal blog; or connect an existing WordPress installation.", comment: "Message description for when a user has no sites.")
    static let accountAndSettings = NSLocalizedString("mySite.noSites.button.accountAndSettings", value: "Account and settings", comment: "Button title. Displays the account and setting screen.")
}
