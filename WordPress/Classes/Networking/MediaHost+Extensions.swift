import Foundation
import WordPressMedia

/// Extends `MediaRequestAuthenticator.MediaHost` so that we can easily
/// initialize it from a given `AbstractPost`.
///
extension MediaHost {
    init(_ post: AbstractPost) {
        self.init(with: post.blog, failure: { error in
            // We just associate a post with the underlying error for simpler debugging.
            WordPressAppDelegate.crashLogging?.logError(error)
        })
   }
}

/// Extends `MediaRequestAuthenticator.MediaHost` so that we can easily
/// initialize it from a given `Blog`.
///
extension MediaHost {
    enum BlogError: Swift.Error {
        case baseInitializerError(error: Error)
    }

    init(with blog: Blog) {
        self.init(with: blog) { error in
            // We'll log the error, so we know it's there, but we won't halt execution.
            WordPressAppDelegate.crashLogging?.logError(error)
        }
    }

    init(with blog: Blog, failure: (BlogError) -> ()) {
        let isAtomic = blog.isAtomic()
        self.init(with: blog, isAtomic: isAtomic, failure: failure)
    }

    init(with blog: Blog, isAtomic: Bool, failure: (BlogError) -> ()) {
        self.init(
            isAccessibleThroughWPCom: blog.isAccessibleThroughWPCom(),
            isPrivate: blog.isPrivate(),
            isAtomic: isAtomic,
            siteID: blog.dotComID?.intValue,
            username: blog.usernameForSite,
            authToken: blog.authToken,
            failure: { error in
                // We just associate a blog with the underlying error for simpler debugging.
                failure(BlogError.baseInitializerError(error: error))
            }
        )
   }
}

/// Extends `MediaRequestAuthenticator.MediaHost` so that we can easily
/// initialize it from a given `Blog`.
///
extension MediaHost {
    init(_ post: ReaderPost) {
        let isAccessibleThroughWPCom = post.isWPCom || post.isJetpack

        // This is the only way in which we can obtain the username and authToken here.
        // It'd be nice if all data was associated with an account instead, for transparency
        // and cleanliness of the code - but this'll have to do for now.

        // We allow a nil account in case the user connected only self-hosted sites.
        let account = try? WPAccount.lookupDefaultWordPressComAccount(in: ContextManager.shared.mainContext)
        let username = account?.username
        let authToken = account?.authToken

        self.init(
            isAccessibleThroughWPCom: isAccessibleThroughWPCom,
            isPrivate: post.isBlogPrivate,
            isAtomic: post.isBlogAtomic,
            siteID: post.siteID?.intValue,
            username: username,
            authToken: authToken,
            failure: { error in
                WordPressAppDelegate.crashLogging?.logError(error)
            }
        )
    }
}
