import UIKit

class RegisterDomainDetailsFooterView: UIView, NibLoadable {

    @IBOutlet weak var submitButton: NUXButton!

    override func awakeFromNib() {
        super.awakeFromNib()
        clipsToBounds = false
        submitButton.isPrimary = true
        backgroundColor = .systemBackground
    }
}
