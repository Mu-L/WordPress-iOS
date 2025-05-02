import Foundation
import WordPressKit

@MainActor
final class SubscribersViewModel: ObservableObject {
    private let blog: Blog

    @Published private(set) var items: [SubscriberRowViewModel] = []
    @Published private(set) var isLoading = false
    @Published private(set) var error: Error?

    private var hasMorePages = true
    private var currentPage = 1
    private var task: Task<Void, Never>?

    init(blog: Blog) {
        self.blog = blog
    }

    func loadMore() {
        guard !isLoading && hasMorePages else {
            return
        }
        actuallyLoadMore()
    }

    func onRowAppear(_ row: SubscriberRowViewModel) {
        guard items.suffix(5).contains(where: { $0.id == row.id }) else {
            return
        }
        if error == nil {
            loadMore()
        }
    }

    func refresh() async {
        task?.cancel()
        currentPage = 1
        hasMorePages = true

        actuallyLoadMore()
        await task?.value
    }

    private func actuallyLoadMore() {
        isLoading = true
        error = nil
        task = Task { @MainActor [currentPage] in
            await actuallyLoadMore(page: currentPage)
        }
    }

    private func actuallyLoadMore(page: Int) async {
        do {
            guard let api = blog.wordPressComRestApi, let siteID = blog.dotComID?.intValue else {
                throw URLError(.unknown)
            }
            let service = PeopleServiceRemote(wordPressComRestApi: api)
            let response = try await service.getSubscribers(siteID: siteID, page: page, perPage: 50)

            if !Task.isCancelled {
                currentPage += 1
                hasMorePages = response.page < response.pages
                isLoading = false
                items = {
                    var items = response.page == 1 ? [] : self.items
                    items += response.subscribers.map(SubscriberRowViewModel.init)
                    return items.deduplicated(by: \.id)
                }()
            }
        } catch {
            if !Task.isCancelled {
                self.error = error
                isLoading = false
            }
        }
    }
}

@MainActor
final class SubscriberRowViewModel: Identifiable {
    let subscriptionID: Int
    let title: String

    init(_ subscriber: RemoteSubscriber) {
        self.subscriptionID = subscriber.subscriptionID
        self.title = "\(subscriber)"
    }
}
