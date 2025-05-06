import Foundation
import WordPressShared
import WordPressKit

/// Loads paginated subscribers for the given parameters.
@MainActor
final class SubscribersPaginatedResponse: ObservableObject {
    @Published private(set) var items: [SubscriberRowViewModel] = []
    @Published private(set) var hasMore = true
    @Published private(set) var isLoading = false
    @Published private(set) var error: Error?

    var isEmpty: Bool { items.isEmpty }

    private var currentPage = 1
    private let blog: Blog
    private let parameters: PeopleServiceRemote.SubscribersParameters
    private let search: String

    init(blog: Blog, parameters: PeopleServiceRemote.SubscribersParameters = .init(), search: String) async throws {
        self.blog = blog
        self.parameters = parameters
        self.search = search

        let response = try await next()
        didLoad(response)
    }

    func loadMore() {
        guard hasMore && !isLoading else {
            return
        }
        error = nil
        isLoading = true
        Task {
            defer { isLoading = false }
            do {
                let response = try await next()
                didLoad(response)
            } catch {
                self.error = error
            }
        }
    }

    private func didLoad(_ response: PeopleServiceRemote.SubscribersResponse) {
        currentPage += 1
        hasMore = response.page < response.pages

        let existingIDs = Set(items.map(\.subscriptionID))
        let newItems = response.subscribers.filter {
            !existingIDs.contains($0.subscriptionID)
        }
        items += newItems.map(SubscriberRowViewModel.init)
    }

    func onRowAppear(_ row: SubscriberRowViewModel) {
        guard items.suffix(5).contains(where: { $0.id == row.id }) else {
            return
        }
        if error == nil {
            loadMore()
        }
    }

    private func next() async throws -> PeopleServiceRemote.SubscribersResponse {
        guard let api = blog.wordPressComRestApi,
                let siteID = blog.dotComID?.intValue else {
            throw URLError(.unknown)
        }
        let service = PeopleServiceRemote(wordPressComRestApi: api)
        return try await service.getSubscribers(
            siteID: siteID,
            page: currentPage,
            perPage: 50,
            parameters: parameters,
            search: search
        )
    }
}
