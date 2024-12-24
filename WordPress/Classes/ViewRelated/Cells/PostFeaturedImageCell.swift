import UIKit
import WordPressUI
import WordPressMedia

final class PostFeaturedImageCell: UITableViewCell {
    let featuredImageView = AsyncImageView()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)

        featuredImageView.configuration.loadingStyle = .spinner

        contentView.addSubview(featuredImageView)
        featuredImageView.pinEdges()
        NSLayoutConstraint.activate([
            featuredImageView.heightAnchor.constraint(equalTo: featuredImageView.widthAnchor, multiplier: ReaderPostCell.coverAspectRatio)
        ])
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    @objc func setImage(withURL url: URL, post: AbstractPost) {
        featuredImageView.setImage(with: url, host: MediaHost(post))
    }
}
