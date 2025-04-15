import UIKit
import WordPressUI

final class ReaderHomeViewController: ReaderStreamViewController {
    private let mainContext = ContextManager.shared.mainContext

    override func viewDidLoad() {
        super.viewDidLoad()

        title = SharedStrings.Reader.home
        navigationItem.rightBarButtonItem = UIBarButtonItem(image: UIImage(named: "wpl-add-card")?.resized(to: CGSize(width: 28, height: 28)), style: .plain, target: self, action: #selector(buttonCreatePostTapped))

        navigationItem.largeTitleDisplayMode = .always
        navigationController?.navigationBar.prefersLargeTitles = true
    }

    override func configureTitleForTopic() {
        // Do nothing
    }

    @objc override func headerForStream(_ topic: ReaderAbstractTopic?, container: UITableViewController) -> UIView? {
        nil
    }

    @objc private func buttonCreatePostTapped() {
        if let blog = Blog.lastUsedOrFirst(in: mainContext) {
            showCreatePostScreen(blog: blog)
        } else {
            showCreateSiteFlow()
        }
    }

    private func showCreateSiteFlow() {
        let wizardLauncher = SiteCreationWizardLauncher()
        guard let wizard = wizardLauncher.ui else {
            return wpAssertionFailure("something went wrong")
        }
        present(wizard, animated: true)
        SiteCreationAnalyticsHelper.trackSiteCreationAccessed(source: "home")
    }

    private func showCreatePostScreen(blog: Blog) {
        let editorVC = EditPostViewController(blog: blog)
        editorVC.entryPoint = .dashboard
        present(editorVC, animated: true)
    }
}
