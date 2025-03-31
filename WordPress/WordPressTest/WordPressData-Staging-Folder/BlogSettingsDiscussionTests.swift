import Foundation
import XCTest
@testable import WordPress // FIXME: BlogSettings+Discussion is not in WordPressData yet
@testable import WordPressData

class BlogSettingsDiscussionTests: CoreDataTestCase {
    func testCommentsAutoapprovalDisabledEnablesManualModerationFlag() {
        let settings = BlogSettings.newSettings(in: mainContext)
        settings.commentsAutoapproval = .disabled
        XCTAssertTrue(settings.commentsRequireManualModeration)
        XCTAssertFalse(settings.commentsFromKnownUsersAllowlisted)
    }

    func testCommentsAutoapprovalFromKnownUsersEnablesAllowlistedFlag() {
        let settings = BlogSettings.newSettings(in: mainContext)
        settings.commentsAutoapproval = .fromKnownUsers
        XCTAssertFalse(settings.commentsRequireManualModeration)
        XCTAssertTrue(settings.commentsFromKnownUsersAllowlisted)
    }

    func testCommentsAutoapprovalEverythingDisablesManualModerationAndAllowlistedFlags() {
        let settings = BlogSettings.newSettings(in: mainContext)
        settings.commentsAutoapproval = .everything
        XCTAssertFalse(settings.commentsRequireManualModeration)
        XCTAssertFalse(settings.commentsFromKnownUsersAllowlisted)
    }

    func testCommentsSortingSetsTheCorrectCommentSortOrderIntegerValue() {
        let settings = BlogSettings.newSettings(in: mainContext)

        settings.commentsSorting = .ascending
        XCTAssertTrue(settings.commentsSortOrder?.intValue == Sorting.ascending.rawValue)

        settings.commentsSorting = .descending
        XCTAssertTrue(settings.commentsSortOrder?.intValue == Sorting.descending.rawValue)
    }

    func testCommentsSortOrderAscendingSetsTheCorrectCommentSortOrderIntegerValue() {
        let settings = BlogSettings.newSettings(in: mainContext)

        settings.commentsSortOrderAscending = true
        XCTAssertTrue(settings.commentsSortOrder?.intValue == Sorting.ascending.rawValue)

        settings.commentsSortOrderAscending = false
        XCTAssertTrue(settings.commentsSortOrder?.intValue == Sorting.descending.rawValue)
    }

    func testCommentsThreadingDisablesSetsThreadingEnabledFalse() {
        let settings = BlogSettings.newSettings(in: mainContext)

        settings.commentsThreading = .disabled
        XCTAssertFalse(settings.commentsThreadingEnabled)
    }

    func testCommentsThreadingEnabledSetsThreadingEnabledTrueAndTheRightDepthValue() {
        let settings = BlogSettings.newSettings(in: mainContext)

        settings.commentsThreading = .enabled(depth: 10)
        XCTAssertTrue(settings.commentsThreadingEnabled)
        XCTAssert(settings.commentsThreadingDepth == 10)

        settings.commentsThreading = .enabled(depth: 2)
        XCTAssertTrue(settings.commentsThreadingEnabled)
        XCTAssert(settings.commentsThreadingDepth == 2)
    }

    // MARK: - Typealiases
    typealias Sorting = BlogSettings.CommentsSorting
}

extension BlogSettings {

    static func newSettings(in context: NSManagedObjectContext) -> BlogSettings {
        let name = BlogSettings.classNameWithoutNamespaces()
        let entity = NSEntityDescription.insertNewObject(forEntityName: name, into: context)

        return entity as! BlogSettings
    }
}
