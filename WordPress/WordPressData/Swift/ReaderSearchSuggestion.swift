import Foundation
import CoreData

// FIXME: Remove from model once transition completed and a new build using it has been shipped
@available(*, deprecated, message: "No longer used")
@objc open class ReaderSearchSuggestion: NSManagedObject {
    @NSManaged open var date: Date?
    @NSManaged open var searchPhrase: String
}
