import UIKit

/// ImmuTableRow represents the minimum common elements of a row model.
///
/// You should implement your own types that conform to ImmuTableRow to define your custom rows.
///
public protocol ImmuTableRow {

    /**
     The closure to call when the row is tapped. The row is passed as an argument to the closure.

     To improve readability, we recommend that you implement the action logic in one of
     your view controller methods, instead of including the closure inline.

     Also, be mindful of retain cycles. If your closure needs to reference `self` in
     any way, make sure to use `[unowned self]` in the parameter list.

     An example row with its action could look like this:

         class ViewController: UITableViewController {

             func buildViewModel() {
                 let item1Row = NavigationItemRow(title: "Item 1", action: navigationAction())
                 ...
             }

             func navigationAction() -> ImmuTableRow -> Void {
                 return { [unowned self] row in
                     let controller = self.controllerForRow(row)
                     self.navigationController?.pushViewController(controller, animated: true)
                 }
             }

             ...

         }

     */
    var action: ImmuTableAction? { get }

    /// This method is called when an associated cell needs to be configured.
    ///
    /// - Precondition: You can assume that the passed cell is of the type defined
    ///   by cell.cellClass and force downcast accordingly.
    ///
    func configureCell(_ cell: UITableViewCell)

    /// An ImmuTableCell value defining the associated cell type.
    ///
    /// - Seealso: See ImmuTableCell for possible options.
    ///
    static var cell: ImmuTableCell { get }

    /// The desired row height (Optional)
    ///
    /// If not defined or nil, the default height will be used.
    ///
    static var customHeight: Float? { get }
}

extension ImmuTableRow {
    public var reusableIdentifier: String {
        return type(of: self).cell.reusableIdentifier
    }

    public var cellClass: UITableViewCell.Type {
        return type(of: self).cell.cellClass
    }

    public static var customHeight: Float? {
        return nil
    }
}
