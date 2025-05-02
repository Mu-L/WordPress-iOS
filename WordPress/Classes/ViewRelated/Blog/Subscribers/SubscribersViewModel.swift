import Foundation
import Combine
import WordPressKit

@MainActor
final class SubscribersViewModel: ObservableObject {
    private let blog: Blog

    @Published private(set) var items: [SubscriberRowViewModel] = []
    @Published private(set) var isLoading = false
    @Published private(set) var error: Error?

    @Published var searchText = ""

    private var response: SubscribersPaginatedResponse
    private var criteria = SubscribersPaginatedResponse.Criteria()
    private var task: Task<Void, Never>? {
        didSet { isLoading = task != nil }
    }

    private var cancellables: [AnyCancellable] = []

    init(blog: Blog) {
        self.blog = blog
        self.response = SubscribersPaginatedResponse(blog: blog, criteria: criteria)

//        $searchText.debounce(for: 0.5, scheduler: RunLoop.main).sink { [weak self] _ in
//            
//        }.store(in: &cancellables)
    }

    func loadMore() {
        guard response.hasMore else {
            return
        }
        error = nil
        task = Task {
            defer { task = nil }
            await _loadMore()
        }
    }

    private func _loadMore() async {
        do {
            let items = try await response.next()
            self.items += items.map(SubscriberRowViewModel.init)
        } catch {
            guard !(error is CancellationError) else { return }
            self.error = error
        }
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
        let response = SubscribersPaginatedResponse(blog: blog, criteria: criteria)
        do {
            let items = try await response.next()
            self.response = response
            self.items = items.map(SubscriberRowViewModel.init)
        } catch {
            Notice(error: error).post()
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
