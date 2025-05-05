import Foundation
import WordPressShared
import WordPressKit

/// Loads paginated subscribers for the given criteria.
@MainActor
final class SubscribersPaginatedResponse {
    private let blog: Blog
    private let parameters: PeopleServiceRemote.SubscribersParameters

    private(set) var items: [RemoteSubscriber] = []
    private(set) var hasMore = true
    private(set) var currentPage = 1

    init(blog: Blog, parameters: PeopleServiceRemote.SubscribersParameters = .init()) {
        self.blog = blog
        self.parameters = parameters
    }

    func next() async throws -> [RemoteSubscriber] {
        guard hasMore else {
            wpAssertionFailure("finished")
            return []
        }

        guard let api = blog.wordPressComRestApi,
                let siteID = blog.dotComID?.intValue else {
            throw URLError(.unknown)
        }

        let service = PeopleServiceRemote(wordPressComRestApi: api)
        let response = try await service.getSubscribers(
            siteID: siteID,
            page: currentPage,
            perPage: 50,
            parameters: parameters
        )

        try Task.checkCancellation()

        currentPage += 1
        hasMore = response.page < response.pages

        let existingIDs = Set(items.map(\.subscriptionID))
        let newItems = response.subscribers.filter {
            !existingIDs.contains($0.subscriptionID)
        }
        items += newItems
        return newItems
    }
}
