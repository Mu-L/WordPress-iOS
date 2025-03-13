import Foundation
import UIKit
import SwiftUI

class WelcomeSplitViewContent: SplitViewDisplayable {
    let supplementary: UINavigationController
    var secondary: UINavigationController

    init(addSite: @escaping (AddSiteMenuViewModel.Selection) -> Void) {
        supplementary = UINavigationController(rootViewController: UnifiedPrologueViewController())

        if let account = try? WPAccount.lookupDefaultWordPressComAccount(in: ContextManager.shared.mainContext) {
            let noSiteView = NoSitesView(account: account, appUIType: JetpackFeaturesRemovalCoordinator.currentAppUIType, onSelection: addSite)
            let noSitesVC = UIHostingController(rootView: noSiteView)
            noSitesVC.view.backgroundColor = .systemBackground
            secondary = UINavigationController(rootViewController: noSitesVC)
        } else {
            // This branch should never execute, because we only show the "Welcome" screen when the WP.com account does not have any sites.
            secondary = UINavigationController()
        }
    }

    func displayed(in splitVC: UISplitViewController) {
        // Do nothing
    }
}
