import UIKit
import WordPressUI

protocol ReaderPostCoverViewDelegate: AnyObject {
    func didTapFeaturedImage()
}

final class ReaderPostCoverView: UIView {
    let imageView = AsyncImageView()

    weak var delegate: ReaderPostCoverViewDelegate?

    override init(frame: CGRect) {
        super.init(frame: frame)

        setupView()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupView() {
        imageView.layer.cornerRadius = 6
        imageView.layer.masksToBounds = true

        addSubview(imageView)
        imageView.pinEdges(insets: UIEdgeInsets(horizontal: 16, vertical: 16))

        NSLayoutConstraint.activate([
            imageView.heightAnchor.constraint(equalTo: imageView.widthAnchor, multiplier: ReaderPostCell.coverAspectRatio)

        ])

        addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(imageTapped)))
    }

    func setImageURL(_ imageURL: URL) {
        imageView.setImage(with: imageURL)
    }

    @objc private func imageTapped(_ sender: UITapGestureRecognizer) {
        delegate?.didTapFeaturedImage()
    }

    static func getFeaturedImageURL(for post: ReaderPost) -> URL? {
        guard let imageURL = URL(string: post.featuredImage) else {
            return nil
        }
        guard !post.contentIncludesFeaturedImage() else {
            return nil
        }
        return imageURL
    }
}
