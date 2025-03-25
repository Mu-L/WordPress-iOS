import CoreData

// FIXME: Remove from model once transition completed and a new build using it has been shipped
@available(*, deprecated, message: "No longer used")
@objc(QuickStartTourState)
open class QuickStartTourState: NSManagedObject {
    // Relations
    @NSManaged open var blog: Blog?
    @NSManaged open var completed: Bool
    @NSManaged open var skipped: Bool

    // Properties
    @NSManaged open var tourID: String
}
