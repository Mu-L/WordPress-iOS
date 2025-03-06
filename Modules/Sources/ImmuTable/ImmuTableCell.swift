import UIKit

// ImmuTableCell describes cell types so they can be registered with a table view.
///
/// It supports two options:
///    - Nib for Interface Builder defined cells.
///    - Class for cells defined in code.
/// Both cases presume a custom UITableViewCell subclass. If you aren't subclassing,
/// you can also use UITableViewCell as the type.
///
/// - Note: If you need to use any cell style other than .Default we recommend you
///  subclass UITableViewCell and override init(style:reuseIdentifier:).
///
public enum ImmuTableCell {

    /// A cell using a UINib. Values are the UINib object and the custom cell class.
    case nib(UINib, UITableViewCell.Type)

    /// A cell using a custom class. The associated value is the custom cell class.
    case `class`(UITableViewCell.Type)

    /// A String that uniquely identifies the cell type
    public var reusableIdentifier: String {
        switch self {
        case .class(let cellClass):
            return NSStringFromClass(cellClass)
        case .nib(_, let cellClass):
            return NSStringFromClass(cellClass)
        }
    }

    /// The class of the custom cell
    public var cellClass: UITableViewCell.Type {
        switch self {
        case .class(let cellClass):
            return cellClass
        case .nib(_, let cellClass):
            return cellClass
        }
    }
}
