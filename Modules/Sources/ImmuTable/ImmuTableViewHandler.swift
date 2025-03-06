import UIKit

/// ImmuTableViewHandler is a helper to facilitate integration of ImmuTable in your
/// table view controllers.
///
/// It acts as the table view data source and delegate, and signals the table view to
/// reload its data when the underlying model changes.
///
/// - Note: As it keeps a weak reference to its target, you should keep a strong
///         reference to the handler from your view controller.
///
open class ImmuTableViewHandler: NSObject, UITableViewDataSource, UITableViewDelegate {

    @objc unowned let target: UIViewControllerWithTableView
    private weak var passthroughScrollViewDelegate: UIScrollViewDelegate?

    /// Initializes the handler with a target table view controller.
    /// - postcondition: After initialization, it becomse the data source and
    ///   delegate for the the target's table view.
    @objc public init(takeOver target: UIViewControllerWithTableView, with passthroughScrollViewDelegate: UIScrollViewDelegate? = nil) {
        self.target = target
        self.passthroughScrollViewDelegate = passthroughScrollViewDelegate

        super.init()

        self.target.tableView.dataSource = self
        self.target.tableView.delegate = self
    }

    /// An ImmuTable object representing the table structure.
    open var viewModel = ImmuTable.Empty {
        didSet {
            if target.isViewLoaded && automaticallyReloadTableView {
                target.tableView.reloadData()
            }
        }
    }

    /// Configure the handler to automatically deselect any cell after tapping it.
    @objc public var automaticallyDeselectCells = false

    /// Automatically reload table view when view model changes
    @objc public var automaticallyReloadTableView = true

    // MARK: UITableViewDataSource

    open func numberOfSections(in tableView: UITableView) -> Int {
        return viewModel.sections.count
    }

    open func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return viewModel.sections[section].rows.count
    }

    open func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let row = viewModel.rowAtIndexPath(indexPath)
        let cell = tableView.dequeueReusableCell(withIdentifier: row.reusableIdentifier, for: indexPath)

        row.configureCell(cell)

        return cell
    }

    open func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return viewModel.sections[section].headerText
    }

    open func tableView(_ tableView: UITableView, titleForFooterInSection section: Int) -> String? {
        return viewModel.sections[section].footerText
    }

    open func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        if target.responds(to: #selector(UITableViewDataSource.tableView(_:canEditRowAt:))) {
            return target.tableView?(tableView, canEditRowAt: indexPath) ?? false
        }

        return false
    }

    open func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool {
        if target.responds(to: #selector(UITableViewDataSource.tableView(_:canMoveRowAt:))) {
            return target.tableView?(tableView, canMoveRowAt: indexPath) ?? false
        }

        return false
    }

    open func tableView(_ tableView: UITableView, moveRowAt sourceIndexPath: IndexPath, to destinationIndexPath: IndexPath) {
        target.tableView?(tableView, moveRowAt: sourceIndexPath, to: destinationIndexPath)
    }

    // MARK: UITableViewDelegate

    open func tableView(_ tableView: UITableView, willSelectRowAt indexPath: IndexPath) -> IndexPath? {
        if target.responds(to: #selector(UITableViewDelegate.tableView(_:willSelectRowAt:))) {
            return target.tableView?(tableView, willSelectRowAt: indexPath)
        } else {
            return indexPath
        }
    }
    open func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if target.responds(to: #selector(UITableViewDelegate.tableView(_:didSelectRowAt:))) {
            target.tableView?(tableView, didSelectRowAt: indexPath)
        } else {
            let row = viewModel.rowAtIndexPath(indexPath)
            row.action?(row)
        }
        if automaticallyDeselectCells {
            tableView.deselectRow(at: indexPath, animated: true)
        }
    }

    open func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        let row = viewModel.rowAtIndexPath(indexPath)
        if let customHeight = type(of: row).customHeight {
            return CGFloat(customHeight)
        }
        return tableView.rowHeight
    }

    open func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        if target.responds(to: #selector(UITableViewDelegate.tableView(_:heightForFooterInSection:))) {
            return target.tableView?(tableView, heightForFooterInSection: section) ?? UITableView.automaticDimension
        }

        return UITableView.automaticDimension
    }

    open func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        if target.responds(to: #selector(UITableViewDelegate.tableView(_:heightForHeaderInSection:))) {
            return target.tableView?(tableView, heightForHeaderInSection: section) ?? UITableView.automaticDimension
        }

        return UITableView.automaticDimension
    }

    open func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        if target.responds(to: #selector(UITableViewDelegate.tableView(_:viewForFooterInSection:))) {
            return target.tableView?(tableView, viewForFooterInSection: section)
        }

        return nil
    }

    open func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        if target.responds(to: #selector(UITableViewDelegate.tableView(_:viewForHeaderInSection:))) {
            return target.tableView?(tableView, viewForHeaderInSection: section)
        }

        return nil
    }

    open func tableView(_ tableView: UITableView, targetIndexPathForMoveFromRowAt sourceIndexPath: IndexPath, toProposedIndexPath proposedDestinationIndexPath: IndexPath) -> IndexPath {
        if target.responds(to: #selector(UITableViewDelegate.tableView(_:targetIndexPathForMoveFromRowAt:toProposedIndexPath:))) {
            return target.tableView?(tableView, targetIndexPathForMoveFromRowAt: sourceIndexPath, toProposedIndexPath: proposedDestinationIndexPath) ?? proposedDestinationIndexPath
        }

        return proposedDestinationIndexPath
    }

    open func tableView(_ tableView: UITableView, editingStyleForRowAt indexPath: IndexPath) -> UITableViewCell.EditingStyle {
        if target.responds(to: #selector(UITableViewDelegate.tableView(_:editingStyleForRowAt:))) {
            return target.tableView?(tableView, editingStyleForRowAt: indexPath)  ?? .none
        }

        return .none
    }

    open func tableView(_ tableView: UITableView, shouldIndentWhileEditingRowAt indexPath: IndexPath) -> Bool {
        return target.tableView?(tableView, shouldIndentWhileEditingRowAt: indexPath) ?? true
    }

    public func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        if target.responds(to: #selector(UITableViewDelegate.tableView(_:trailingSwipeActionsConfigurationForRowAt:))) {
            return target.tableView?(tableView, trailingSwipeActionsConfigurationForRowAt: indexPath)
        }

        return nil
    }

    // MARK: UIScrollViewDelegate

    open func scrollViewDidScroll(_ scrollView: UIScrollView) {
        passthroughScrollViewDelegate?.scrollViewDidScroll?(scrollView)
    }

    open func scrollViewDidZoom(_ scrollView: UIScrollView) {
        passthroughScrollViewDelegate?.scrollViewDidZoom?(scrollView)
    }

    open func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        passthroughScrollViewDelegate?.scrollViewWillBeginDragging?(scrollView)
    }

    open func scrollViewWillEndDragging(_ scrollView: UIScrollView, withVelocity velocity: CGPoint, targetContentOffset: UnsafeMutablePointer<CGPoint>) {
        passthroughScrollViewDelegate?.scrollViewWillEndDragging?(scrollView, withVelocity: velocity, targetContentOffset: targetContentOffset)
    }

    open func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        passthroughScrollViewDelegate?.scrollViewDidEndDragging?(scrollView, willDecelerate: decelerate)
    }

    open func scrollViewWillBeginDecelerating(_ scrollView: UIScrollView) {
        passthroughScrollViewDelegate?.scrollViewWillBeginDecelerating?(scrollView)
    }

    open func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        passthroughScrollViewDelegate?.scrollViewDidEndDecelerating?(scrollView)
    }

    open func scrollViewDidEndScrollingAnimation(_ scrollView: UIScrollView) {
        passthroughScrollViewDelegate?.scrollViewDidEndScrollingAnimation?(scrollView)
    }

    open func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        return passthroughScrollViewDelegate?.viewForZooming?(in: scrollView)
    }

    open func scrollViewWillBeginZooming(_ scrollView: UIScrollView, with view: UIView?) {
        passthroughScrollViewDelegate?.scrollViewWillBeginZooming?(scrollView, with: view)
    }

    open func scrollViewDidEndZooming(_ scrollView: UIScrollView, with view: UIView?, atScale scale: CGFloat) {
        passthroughScrollViewDelegate?.scrollViewDidEndZooming?(scrollView, with: view, atScale: scale)
    }

    open func scrollViewShouldScrollToTop(_ scrollView: UIScrollView) -> Bool {
        return passthroughScrollViewDelegate?.scrollViewShouldScrollToTop?(scrollView) ?? true
    }

    open func scrollViewDidScrollToTop(_ scrollView: UIScrollView) {
        passthroughScrollViewDelegate?.scrollViewDidScrollToTop?(scrollView)
    }

    open func scrollViewDidChangeAdjustedContentInset(_ scrollView: UIScrollView) {
        passthroughScrollViewDelegate?.scrollViewDidChangeAdjustedContentInset?(scrollView)
    }
}
