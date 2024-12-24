import UIKit
import WordPressUI

final class LightboxImagePageViewController: UIViewController {
    private(set) var scrollView = LightboxImageScrollView()
    private let controller = ImageLoadingController()
    private let image: LightboxItem
    private let activityIndicator = UIActivityIndicatorView()
    private var errorView: UIImageView?

    init(image: LightboxItem) {
        self.image = image
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        view.addSubview(scrollView)

        activityIndicator.hidesWhenStopped = true
        view.addSubview(activityIndicator)
        activityIndicator.pinCenter()

        scrollView.onDismissTapped = { [weak self] in
            self?.parent?.presentingViewController?.dismiss(animated: true)
        }

        controller.onStateChanged = { [weak self] in
            self?.setState($0)
        }

        controller.setImage(with: image.sourceURL, host: image.host)
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        if scrollView.frame != view.bounds {
            scrollView.frame = view.bounds
            scrollView.configureLayout()
        }
    }

    private func setState(_ state: ImageLoadingController.State) {
        switch state {
        case .loading:
            if scrollView.imageView.image == nil {
                activityIndicator.startAnimating()
            }
        case .success(let image):
            activityIndicator.stopAnimating()
            scrollView.configure(with: image)
        case .failure:
            activityIndicator.stopAnimating()
            makeErrorView().isHidden = false
        }
    }

    private func makeErrorView() -> UIImageView {
        if let errorView {
            return errorView
        }
        let errorView = UIImageView(image: UIImage(systemName: "exclamationmark.triangle"))
        errorView.tintColor = .separator
        view.addSubview(errorView)
        errorView.pinCenter()
        self.errorView = errorView
        return errorView
    }
}
