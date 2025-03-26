import Foundation
import WordPressShared

extension WPAppAnalytics {
    static func track(_ stat: WPAnalyticsStat, properties: [String: Any]? = nil, blog: Blog) {
        track(stat, properties: properties, blogID: blog.dotComID)
    }

    static func track(_ stat: WPAnalyticsStat, properties: [String: Any]? = nil, blogID: NSNumber?) {
        if Thread.isMainThread {
            _track(stat, properties: properties, blogID: blogID)
        } else {
            DispatchQueue.main.async {
                _track(stat, properties: properties, blogID: blogID)
            }
        }
    }

    private static func _track(_ stat: WPAnalyticsStat, properties: [String: Any]? = nil, blogID: NSNumber?) {
        var properties = properties ?? [:]
        if let blogID {
            properties[WPAppAnalyticsKeyBlogID] = blogID
            properties[WPAppAnalyticsKeySiteType] = siteType(forBlogID: blogID)
        }
        if properties.isEmpty {
            WPAppAnalytics.track(stat)
        } else {
            WPAppAnalytics.track(stat, withProperties: properties)
        }
    }

    private static func siteType(forBlogID blogID: NSNumber) -> String {
        wpAssert(Thread.isMainThread)
        let context = ContextManager.shared.mainContext
        if let blog = Blog.lookup(withID: blogID, in: context), blog.isWPForTeams() {
            return WPAppAnalyticsValueSiteTypeP2
        }
        return WPAppAnalyticsValueSiteTypeBlog
    }
}
