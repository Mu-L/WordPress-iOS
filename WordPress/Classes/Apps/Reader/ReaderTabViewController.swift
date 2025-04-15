import Combine
import UIKit
import SwiftUI
import WordPressUI

final class ReaderTabViewController: UITabBarController, UITabBarControllerDelegate {
    private var menuStore = ReaderMenuStore()
    private let library = ReaderPresenter(
        viewModel: ReaderSidebarViewModel(isReaderAppModeEnabled: true)
    )
    private let notificationsButtonViewModel = NotificationsButtonViewModel()
    private var cancellables: [AnyCancellable] = []

    override func viewDidLoad() {
        super.viewDidLoad()

        delegate = self

        if ReaderSidebarViewModel().getTopic(for: .following) != nil {
            setupViewControllers()
        } else {
            loadMenuItems()
        }
    }

    // TODO: (reader) remove the need to fetch the menu on first launch before showing anything
    private func loadMenuItems() {
        let activityIndicator = UIActivityIndicatorView()
        activityIndicator.startAnimating()
        view.addSubview(activityIndicator)
        activityIndicator.pinCenter()

        menuStore.onCompletion = { [weak self] in
            activityIndicator.removeFromSuperview()
            self?.setupViewControllers()
            self?.menuStore.onCompletion = nil
        }
        menuStore.refreshMenu()
    }

    private func setupViewControllers() {
        if #available(iOS 18, *) {
            setupModernTabBarItems()
        } else {
            setupLegacyTabBarItems()
        }
    }

    @available(iOS 18, *)
    private func setupModernTabBarItems() {
        let home = UITab(title: SharedStrings.Reader.home, image: UIImage(named: "reader-menu-home"), identifier: "home") { [unowned self] _ in
            self.makeHomeViewController()
        }
        let library = UITab(title: SharedStrings.Reader.library, image: UIImage(named: "reader-menu-subscriptions"), identifier: "library") { [unowned self] _ in
            self.makeLibraryViewController()
        }
        let discover = UITab(title: SharedStrings.Reader.discover, image: UIImage(named: "reader-menu-explorer"), identifier: "discover") { [unowned self] _ in
            self.makeDiscoverViewController()
        }

        let notifications = UITab(title: SharedStrings.Reader.activity, image: UIImage(named: "tab-bar-notifications"), identifier: "activity") { [unowned self] _ in
            self.makeActivityViewController()
        }
        notificationsButtonViewModel.$counter.sink { [weak notifications] count in
            notifications?.badgeValue = count == 0 ? nil : "1"
        }.store(in: &cancellables)

        let me = UITab(title: SharedStrings.Reader.me, image: UIImage(named: "tab-bar-me"), identifier: "me") { [unowned self] _ in
            self.makeMeViewController()
        }
        // TODO: (reader) observe gravatar updates
        if let account = try? WPAccount.lookupDefaultWordPressComAccount(in: ContextManager.shared.mainContext),
           let avatarURL = account.avatarURL.flatMap(URL.init) {
            Task { @MainActor [weak me] in
                do {
                    let image = try await ImageDownloader.shared.image(from: avatarURL)
                    me?.image = image.gravatarIcon(size: 26.0)
//                    meVC?.tabBarItem.configureGravatarImage(image)
                } catch {
                    // Do nothing
                }
            }
        }

        tabs = [
            home,
            library,
            discover,
            notifications,
            me
        ]
    }

    private func setupLegacyTabBarItems() {
        let homeVC = makeHomeViewController()
        homeVC.tabBarItem = UITabBarItem(
            title: SharedStrings.Reader.home,
            image: UIImage(named: "reader-menu-home"),
            selectedImage: nil
        )

        let libraryVC = makeLibraryViewController()
        libraryVC.tabBarItem = UITabBarItem(
            title: SharedStrings.Reader.library,
            image: UIImage(named: "reader-menu-subscriptions"),
            selectedImage: nil
        )

        let discoverVC = makeDiscoverViewController()
        discoverVC.tabBarItem = UITabBarItem(
            title: SharedStrings.Reader.discover,
            image: UIImage(named: "reader-menu-explorer"),
            selectedImage: nil
        )

        let activityVC = makeActivityViewController()
        activityVC.tabBarItem = UITabBarItem(
            title: SharedStrings.Reader.activity,
            image: UIImage(named: "tab-bar-notifications"),
            selectedImage: UIImage(named: "tab-bar-notifications")
        )

        notificationsButtonViewModel.$counter.sink { [weak activityVC] count in
            let image = UIImage(named: count == 0 ? "tab-bar-notifications" : "tab-bar-notifications-unread")
            activityVC?.tabBarItem.image = image
            activityVC?.tabBarItem.selectedImage = image
        }.store(in: &cancellables)

        let meVC = makeMeViewController()
        meVC.tabBarItem = UITabBarItem(
            title: SharedStrings.Reader.me,
            image: UIImage(named: "tab-bar-me"),
            selectedImage: UIImage(named: "tab-bar-me")
        )
        // TODO: (reader) observe gravatar updates
        if let account = try? WPAccount.lookupDefaultWordPressComAccount(in: ContextManager.shared.mainContext),
           let avatarURL = account.avatarURL.flatMap(URL.init) {
            Task { @MainActor [weak meVC] in
                do {
                    let image = try await ImageDownloader.shared.image(from: avatarURL)
                    meVC?.tabBarItem.configureGravatarImage(image)
                } catch {
                    // Do nothing
                }
            }
        }

        self.viewControllers = [
            homeVC,
            libraryVC,
            discoverVC,
            activityVC,
            meVC
        ]
    }

    // MARK: - Tabs

    private func makeHomeViewController() -> UIViewController {
        let homeVC = ReaderHomeViewController()
        // TODO: (reader) refactor to not require `topic`
        homeVC.readerTopic = ReaderSidebarViewModel().getTopic(for: .following)

        // TODO: (reader) remove it; had to use due to how ghosts are implemented (separate table)
        homeVC.tabBarItem.scrollEdgeAppearance = {
            let appearance = UITabBarAppearance()
            appearance.configureWithOpaqueBackground()
            return appearance
        }()
        return UINavigationController(rootViewController: homeVC)
    }

    private func makeLibraryViewController() -> UIViewController {
        let libraryVC = library.sidebar

        libraryVC.tabBarItem.scrollEdgeAppearance = {
            let appearance = UITabBarAppearance()
            appearance.configureWithOpaqueBackground()
            return appearance
        }()
        return library.prepareForLibraryPresentation()
    }

    private func makeDiscoverViewController() -> UIViewController {
        let discoverVC: UIViewController = {
            // TODO: (reader) refactor to not require `topic`
            if let topic = ReaderSidebarViewModel().getTopic(for: .discover) {
                ReaderDiscoverTabViewController(topic: topic)
            } else {
                UIViewController()
            }
        }()

        discoverVC.tabBarItem.scrollEdgeAppearance = {
            let appearance = UITabBarAppearance()
            appearance.configureWithOpaqueBackground()
            return appearance
        }()
        let navigationVC = UINavigationController(rootViewController: discoverVC)
        navigationVC.navigationBar.prefersLargeTitles = true
        return navigationVC
    }

    private func makeActivityViewController() -> UIViewController {
        let notificationsVC = UIStoryboard(name: "Notifications", bundle: nil)
            .instantiateInitialViewController() as! NotificationsViewController

        notificationsVC.title = SharedStrings.Reader.activity
        notificationsVC.isReaderAppModeEnabled = true
        let navigationVC = UINavigationController(rootViewController: notificationsVC)
        notificationsVC.enableLargeTitles()

        return navigationVC
    }

    private func makeMeViewController() -> UIViewController {
        let meVC = ReaderProfileViewController()
        return UINavigationController(rootViewController: meVC)
    }

    // MAKR: - UITabBarControllerDelegate

    func tabBarController(_ tabBarController: UITabBarController, shouldSelect viewController: UIViewController) -> Bool {
        if selectedIndex == viewControllers?.firstIndex(of: viewController) {
            (viewController as? UINavigationController)?.scrollContentToTopAnimated(true)
        }
        return true
    }
}

private extension UIViewController {
    func enableLargeTitles() {
        assert(navigationController != nil)
        navigationItem.largeTitleDisplayMode = .always
        navigationController?.navigationBar.prefersLargeTitles = true
    }
}
