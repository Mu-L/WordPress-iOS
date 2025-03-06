import UIKit

public class ImmuTableDiffableViewHandler: ImmuTableViewHandler {
    public lazy var diffableDataSource: ImmuTableDiffableDataSource = {
        return ImmuTableDiffableDataSource(tableView: target.tableView) { tableView, indexPath, item in
            let row = item.immuTableRow
            let cell = tableView.dequeueReusableCell(withIdentifier: row.reusableIdentifier, for: indexPath)
            row.configureCell(cell)
            return cell
        }
    }()

    public override init(takeOver target: UIViewControllerWithTableView, with passthroughScrollViewDelegate: UIScrollViewDelegate? = nil) {
        super.init(takeOver: target, with: passthroughScrollViewDelegate)

        self.target.tableView.dataSource = diffableDataSource
        self.automaticallyReloadTableView = false
    }

    func item(for indexPath: IndexPath) -> ImmuTableRow? {
        guard let diffableDataSource = target.tableView.dataSource as? UITableViewDiffableDataSource<AnyHashable, AnyHashableImmuTableRow> else {
            return nil
        }

        return diffableDataSource.itemIdentifier(for: indexPath)?.immuTableRow
    }

    open override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if target.responds(to: #selector(UITableViewDelegate.tableView(_:didSelectRowAt:))) {
            target.tableView?(tableView, didSelectRowAt: indexPath)
        } else if let item = item(for: indexPath) {
            item.action?(item)
        }
        if automaticallyDeselectCells {
            tableView.deselectRow(at: indexPath, animated: true)
        }
    }

    open override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if let item = item(for: indexPath), let customHeight = type(of: item).customHeight {
            return CGFloat(customHeight)
        }
        return tableView.rowHeight
    }
}
