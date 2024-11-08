import Foundation

@objc open class ReaderDefaultTopic: ReaderAbstractTopic {
    override open class var TopicType: String {
        return "default"
    }

    /// - note: Starting with 25.5, the app no longer uses the default topics
    /// fetched from `/read/menu`. Instead, it uses the topics created locally.
    /// The only reason these topics are needed is to filter entities in Core Data.
    static func make(path: Path, in context: NSManagedObjectContext) throws -> ReaderDefaultTopic {
        if let topic = context.firstObject(ofType: ReaderDefaultTopic.self, matching: NSPredicate(format: "path == %@", path.rawValue)) {
            return topic
        }
        let topic = ReaderDefaultTopic(entity: ReaderDefaultTopic.entity(), insertInto: context)
        topic.type = TopicType
        topic.path = path.rawValue
        topic.title = ""
        try context.save()
        return topic
    }

    enum Path: String {
        // These are arbitrary values just to identify the entites.
        case recommended = "/jpios/discover/recommended"
        case firstPosts = "/jpios/discover/first-posts"
        case latest = "/jpios/discover/latest"
        case recent = "/jpios/recent"
        case liked = "/jpios/liked"
    }
}
