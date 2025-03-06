import UIKit

extension UITableView: CellRegistrar {
    public func register(_ cell: ImmuTableCell, cellReuseIdentifier: String) {
        switch cell {
        case .nib(let nib, _):
            self.register(nib, forCellReuseIdentifier: cell.reusableIdentifier)
        case .class(let cellClass):
            self.register(cellClass, forCellReuseIdentifier: cell.reusableIdentifier)
        }
    }
}
