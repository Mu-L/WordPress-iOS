import Foundation
import WordPressKit

/// Loads paginated subscribers for the given criteria.
@MainActor
final class SubscribersPaginatedResponse {
    private let blog: Blog
    private let criteria: Criteria

    private(set) var items: [RemoteSubscriber] = []
    private(set) var hasMore = true
    private(set) var currentPage = 1

    struct Criteria: Hashable {
        var searchText = ""
    }

    init(blog: Blog, criteria: Criteria) {
        self.blog = blog
        self.criteria = criteria
    }

    func next() async throws -> [RemoteSubscriber] {
        guard hasMore else {
            return []
        }
        guard let api = blog.wordPressComRestApi, let siteID = blog.dotComID?.intValue else {
            throw URLError(.unknown)
        }
        let service = PeopleServiceRemote(wordPressComRestApi: api)
        let response = try await service.getSubscribers(siteID: siteID, page: currentPage, perPage: 50)

        // TODO: find a better way to reuse these tasks without relying on cancellation
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
