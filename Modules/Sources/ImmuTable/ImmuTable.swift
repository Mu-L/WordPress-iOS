import UIKit

/**
 ImmuTable represents the view model for a static UITableView.

 ImmuTable consists of zero or more sections, each one containing zero or more rows,
 and an optional header and footer text.

 Each row contains the model necessary to configure a specific type of UITableViewCell.

 To use ImmuTable, first you need to create some custom rows. An example row for a cell
 that acts as a button which performs a destructive action could look like this:

     struct DestructiveButtonRow: ImmuTableRow {
         static let cell = ImmuTableCell.Class(UITableViewCell.self)
         let title: String
         let action: ImmuTableAction?

         func configureCell(cell: UITableViewCell) {
             cell.textLabel?.text = title
             cell.textLabel?.textAlignment = .Center
             cell.textLabel?.textColor = UIColor.redColor()
         }
     }

 The easiest way to use ImmuTable is through ImmuTableViewHandler, which takes a
 UITableViewController as an argument, and acts as the table view delegate and data
 source. You would then assign an ImmuTable object to the handler's `viewModel`
 property.

 - attention: before using any ImmuTableRow type, you need to call `registerRows(_:tableView:)`
 passing the row type. This is needed so ImmuTable can register the class or nib with the table view.
 If you fail to do this, UIKit will raise an exception when it tries to load the row.
 */
public struct ImmuTable {
    /// An array of the sections to be represented in the table view
    public let sections: [ImmuTableSection]

    /// Initializes an ImmuTable object with the given sections
    public init(sections: [ImmuTableSection]) {
        self.sections = sections
    }

    /// Returns the row model for a specific index path.
    ///
    /// - Precondition: `indexPath` should represent a valid section and row, otherwise this method
    ///                 will raise an exception.
    ///
    public func rowAtIndexPath(_ indexPath: IndexPath) -> ImmuTableRow {
        return sections[indexPath.section].rows[indexPath.row]
    }

    /// Registers the row custom class or nib with the table view so it can later be
    /// dequeued with `dequeueReusableCellWithIdentifier(_:forIndexPath:)`
    ///
    public static func registerRows(_ rows: [ImmuTableRow.Type], tableView: UITableView) {
        registerRows(rows, registrator: tableView)
    }

    /// This function exists for testing purposes
    /// - seealso: registerRows(_:tableView:)
    internal static func registerRows(_ rows: [ImmuTableRow.Type], registrator: CellRegistrar) {
        let registrables = rows.reduce([:]) {
            (classes, row) -> [String: ImmuTableCell] in

            var classes = classes
            classes[row.cell.reusableIdentifier] = row.cell
            return classes
        }
        for (identifier, registrable) in registrables {
            registrator.register(registrable, cellReuseIdentifier: identifier)
        }
    }
}
