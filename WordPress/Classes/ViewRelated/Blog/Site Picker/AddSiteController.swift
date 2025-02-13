import UIKit
import SwiftUI

/// Manages the site creation flows.
@MainActor
struct AddSiteController {
    let viewController: UIViewController
    let source: String

    let selfHostedSiteAuthenticator = SelfHostedSiteAuthenticator(session: .shared)

    func showSiteCreationScreen(selection: AddSiteMenuViewModel.Selection) {
        switch selection {
        case .dotCom: showDotComSiteCreationScreen()
        case .selfHosted: showSelfHostedSiteLoginScreen()
        }
    }

    func showDotComSiteCreationScreen() {
        JetpackFeaturesRemovalCoordinator.presentSiteCreationOverlayIfNeeded(in: viewController, source: source, onDidDismiss: { [weak viewController] in
            guard JetpackFeaturesRemovalCoordinator.siteCreationPhase() != .two else {
                return
            }
            // Display site creation flow if not in phase two
            let wizardLauncher = SiteCreationWizardLauncher()
            guard let wizard = wizardLauncher.ui else {
                return
            }
            RootViewCoordinator.shared.isSiteCreationActive = true
            viewController?.present(wizard, animated: true)
            SiteCreationAnalyticsHelper.trackSiteCreationAccessed(source: source)
        })
    }

    func showSelfHostedSiteLoginScreen() {
//        guard FeatureFlag.authenticateUsingApplicationPassword.enabled else {
//            WordPressAuthenticator.showLoginForSelfHostedSite(viewController)
//            return
//        }

        selfHostedSiteAuthenticator.presentLoginScreenOverlay(from: self.viewController) { credentials in
            
        }
    }
}

struct AddSiteMenuViewModel {
    let actions: [Action]

    enum Selection: String {
        case dotCom
        case selfHosted
    }

    struct Action: Identifiable {
        let id = UUID()
        let title: String
        let handler: () -> Void

        var uiAction: UIAction {
            UIAction(title: title, handler: { _ in handler() })
        }
    }

    init(context: ContextManager = .shared, onSelection: @escaping (Selection) -> Void) {
        let defaultAccount = try? WPAccount.lookupDefaultWordPressComAccount(in: context.mainContext)
        let canAddSelfHostedSite = AppConfiguration.showAddSelfHostedSiteButton

        var actions: [Action] = []
        if defaultAccount != nil {
            actions.append(Action(title: Strings.createDotComSite) {
                onSelection(.dotCom)
            })
        }

        if canAddSelfHostedSite {
            actions.append(Action(title: Strings.addSelfHostedSite) {
                onSelection(.selfHosted)
            })
        }
        self.actions = actions
    }
}

extension AddSiteMenuViewModel {
    func makeBarButtonItem() -> UIBarButtonItem? {
        let actions = self.actions
        guard !actions.isEmpty else {
            return nil
        }
        let item = UIBarButtonItem(systemItem: .add)
        item.setAdaptiveActions(actions.map(\.uiAction))
        item.accessibilityIdentifier = "add-site-button"
        return item
    }
}

private enum Strings {
    static let createDotComSite = NSLocalizedString("button.createDotCoSite", value: "Create WordPress.com site", comment: "Create WordPress.com site button")
    static let addSelfHostedSite = NSLocalizedString("button.addSelfHostedSite", value: "Add self-hosted site", comment: "Add self-hosted site button")
}
