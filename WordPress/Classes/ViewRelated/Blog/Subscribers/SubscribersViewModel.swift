import Foundation
import WordPressKit

@MainActor
final class SubscribersViewModel: ObservableObject {
    private let blog: Blog

    @Published private(set) var subscribers: [SubscriberRowViewModel] = []
    @Published private(set) var isLoading: Bool = false
    @Published private(set) var error: Error? = nil
    @Published private(set) var currentPage: Int = 1
    @Published private(set) var hasMorePages: Bool = true

    private var task: Task<Void, Never>?

    init(blog: Blog) {
        self.blog = blog
    }

    func loadMore() async {
        guard !isLoading && hasMorePages else { return }

        guard let api = blog.wordPressComRestApi,
              let siteID = blog.dotComID?.intValue else {
            self.error = URLError(.unknown)
            return
        }

        self.isLoading = true

        let service = PeopleServiceRemote(wordPressComRestApi: api)
        do {
            let response = try await service.getSubscribers(siteID: siteID, page: currentPage, perPage: 50)
            currentPage += 1
            hasMorePages = response.pages >= currentPage
            subscribers += response.subscribers.map(SubscriberRowViewModel.init)
            isLoading = false
        } catch {
            self.error = error
            isLoading = false
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
