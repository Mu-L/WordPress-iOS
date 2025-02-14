import UIKit

final class CommentContextMenu {
    let comment: Comment

    @Published private(set) var isPerformingAction = false

    private weak var presentingViewController: UIViewController?
    private let coreDataStack = ContextManager.shared

    init(comment: Comment, presentingViewController: UIViewController) {
        self.comment = comment
        self.presentingViewController = presentingViewController
    }

    func makeMenu() -> UIMenu {
        UIMenu(options: .displayInline, children: [
            UIDeferredMenuElement.uncached {
                $0(self.makeMenuItems())
            }
        ])
    }

    private func makeMenuItems() -> [UIMenuElement] {
        var items: [UIMenuElement] = []
        if comment.allowsModeration() {
            items += [UIMenu(options: [.displayInline], children: [
                edit, share
            ])]
            items += [UIMenu(options: [.displayInline], children: [
                unapprove, spam, trash
            ])]
        }
        return items
    }

    // MARK: Actions

    private var unapprove: UIAction {
        UIAction(title: Strings.unapprove, image: UIImage(systemName: "x.circle"), attributes: [.destructive]) { _ in
            self.setStatus(.pending)
        }
    }

    private var spam: UIAction {
        UIAction(title: Strings.spam, image: UIImage(systemName: "exclamationmark.octagon"), attributes: [.destructive]) { _ in
            self.setStatus(.spam)
        }
    }

    private var trash: UIAction {
        UIAction(title: Strings.trash, image: UIImage(systemName: "trash"), attributes: [.destructive]) { _ in
            self.setStatus(.unapproved)
        }
    }

    private var edit: UIAction {
        UIAction(title: Strings.edit, image: UIImage(systemName: "pencil")) { _ in
            // TODO: perform
        }
    }

    private var share: UIAction {
        UIAction(title: SharedStrings.Button.share, image: UIImage(systemName: "square.and.arrow.up")) { _ in
            // TODO: perform
        }
    }

    // MARK: Helpers (Moderation)

    // TODO: add spinner
    private func setStatus(_ status: CommentStatusType) {
        let service = CommentService(coreDataStack: coreDataStack)

        self.isPerformingAction = true

        let success: (String) -> Void = { [comment] message in
            service.updateRepliesVisibility(for: comment) {
//                // TODO: (kean) do we need this? probably replace with notifiations
//                self.commentModified = true
//                self.refreshAfterCommentModeration()
//
                self.isPerformingAction = false
                UINotificationFeedbackGenerator().notificationOccurred(.success)

                if status == .approved {
                    Notice(title: message).post()
                } else {
                    Notice(title: message, actionTitle: SharedStrings.Button.undo) { _ in
                        self.setStatus(.approved)
                    }.post()
                }
            }
        }

        let failure: (String, Error?) -> Void = { message, error in
            self.isPerformingAction = false
            UINotificationFeedbackGenerator().notificationOccurred(.error)
            Notice(title: message, message: error?.localizedDescription.stringByDecodingXMLCharacters()).post()
        }

        switch status {
        case .pending:
            service.unapproveComment(comment) {
                success(Strings.pendingSuccess)
            } failure: {
                failure(Strings.pendingFailed, $0)
            }
        case .spam:
            service.spamComment(comment) {
                success(Strings.spamSuccess)
            } failure: {
                failure(Strings.spamFailed, $0)
            }
        case .unapproved: // trash
            service.trashComment(comment) {
                success(Strings.trashSuccess)
            } failure: {
                failure(Strings.trashFailed, $0)
            }
        case .approved:
            service.approve(comment) {
                success(Strings.approveSuccess)
            } failure: {
                failure(Strings.approveFailed, $0)
            }
        default:
            break
        }
    }

    // MARK: Helpers (Other)

    private func showEditScreen() {
        let editVC = EditCommentTableViewController(comment: comment) { comment, commentChanged in
            guard commentChanged else {
                return
            }
            CommentAnalytics.trackCommentEdited(comment: comment)
//
//            self?.commentService.uploadComment(comment, success: {
//                // TODO: needed?
////                self?.commentModified = true
//
//                // update the thread again in case the approval status changed.
////                tableView.reloadRows(at: [indexPath], with: .automatic)
//            }, failure: {
//                self?.displayNotice(title: .editCommentFailureNoticeText)
//            })
        }

        let navigationVC = UINavigationController(rootViewController: editVC)
        presentingViewController?.present(navigationVC, animated: true)
    }
}

private enum Strings {
    static let unapprove = NSLocalizedString("comments.action.unapprove", value: "Unapprove", comment: "Unapproves a comment")
    static let spam = NSLocalizedString("comments.action.spam", value: "Mark as Spam", comment: "Marks comment as spam")
    static let trash = NSLocalizedString("comments.action.trash", value: "Move to Trash", comment: "Trashes the comment")
    static let edit = NSLocalizedString("comments.action.edit", value: "Edit", comment: "Edits the comment")

    static let pendingSuccess = NSLocalizedString("comments.notice.pendingSuccess", value:"Comment set to pending", comment: "Message displayed when pending a comment succeeds.")
    static let pendingFailed = NSLocalizedString("comments.notice.pendingFailed", value:"Error setting comment to pending", comment: "Message displayed when pending a comment fails.")
    static let spamSuccess = NSLocalizedString("comments.notice.spamSuccess", value:"Comment marked as spam", comment: "Message displayed when spamming a comment succeeds.")
    static let spamFailed = NSLocalizedString("comments.notice.spamFailed", value:"Error marking comment as spam", comment: "Message displayed when spamming a comment fails.")
    static let trashSuccess = NSLocalizedString("comments.notice.trashSuccess", value:"Comment moved to trash", comment: "Message displayed when trashing a comment succeeds.")
    static let trashFailed = NSLocalizedString("comments.notice.trashFailed", value:"Error moving comment to trash", comment: "Message displayed when trashing a comment fails.")
    static let approveSuccess = NSLocalizedString("comments.notice.approveSuccess", value:"Comment set to approved", comment: "Message displayed when approving a comment succeeds.")
    static let approveFailed = NSLocalizedString("comments.notice.approveFailed", value:"Error setting comment to approved", comment: "Message displayed when approving a comment fails.")
}
