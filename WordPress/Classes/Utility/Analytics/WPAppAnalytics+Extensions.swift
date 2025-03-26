import Foundation
import WordPressShared

extension WPAppAnalytics {

    // MARK: WPAppAnalytics (Blog)

    static func track(_ stat: WPAnalyticsStat, properties: [String: Any]? = nil, blog: Blog) {
        var properties = properties ?? [:]
        if let blogID = blog.dotComID {
            properties[WPAppAnalyticsKeyBlogID] = blogID
        }
        properties[WPAppAnalyticsKeySiteType] = siteType(for: blog)

        WPAppAnalytics.track(stat, withProperties: properties)
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
        wpAssert(Thread.isMainThread)

        var properties = properties ?? [:]
        if let blogID {
            properties[WPAppAnalyticsKeyBlogID] = blogID

            let context = ContextManager.shared.mainContext
            if let blog = Blog.lookup(withID: blogID, in: context) {
                properties[WPAppAnalyticsKeySiteType] = siteType(for: blog)
            }
        }

        WPAppAnalytics.track(stat, withProperties: properties)
    }

    private static func siteType(for blog: Blog) -> String {
        blog.isWPForTeams() ? WPAppAnalyticsValueSiteTypeP2 : WPAppAnalyticsValueSiteTypeBlog
    }

    // MARK: WPAppAnalytics (AbstractPost)

    static func track(_ stat: WPAnalyticsStat, properties: [String: Any]? = nil, post: AbstractPost) {
        var properties = properties ?? [:]

        if let postID = post.postID, postID > 0 {
            properties[WPAppAnalyticsKeyPostID] = postID
        }
        properties[WPAppAnalyticsKeyHasGutenbergBlocks] = post.containsGutenbergBlocks()

        WPAppAnalytics.track(stat, properties: properties, blog: post.blog)
    }
}
