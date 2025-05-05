import Foundation
import WordPressKit

@MainActor
final class SubscribersViewModel: ObservableObject {
    private let blog: Blog

    @Published private(set) var items: [SubscriberRowViewModel] = []
    @Published private(set) var isLoading = false
    @Published private(set) var error: Error?

    @Published var searchText = "" {
        didSet {
            guard oldValue != searchText else { return }
            didUpdateSearchText(searchText)
        }
    }

    private var response: SubscribersPaginatedResponse
    private var searchResponse: SubscribersPaginatedResponse?

    private var task: Task<Void, Never>? {
        didSet { isLoading = task != nil }
    }

    init(blog: Blog) {
        self.blog = blog
        self.response = SubscribersPaginatedResponse(blog: blog)
    }

    func loadMore() {
        loadMore(for: searchResponse ?? response)
    }

    private func loadMore(for response: SubscribersPaginatedResponse) {
        guard response.hasMore else {
            return
        }
        guard task == nil else {
            return
        }
        error = nil
        task = Task {
            // TODO: do not do this on cancellation
            defer { task = nil }
            do {
                let items = try await response.next()
                self.items += items.map(SubscriberRowViewModel.init)
            } catch {
                guard !(error is CancellationError) else { return }
                self.error = error
            }
        }
    }

    // TODO: (kean) how do we handle refresh for searchResponse?
    func refresh() async {
        task?.cancel()
        task = Task {
            defer { task = nil }
            await _refresh()
        }
        await task?.value
    }

    private func _refresh() async {
        let response = SubscribersPaginatedResponse(
            blog: blog,
            parameters: .init(search: searchText)
        )
        do {
            let items = try await response.next()
            self.response = response
            self.items = items.map(SubscriberRowViewModel.init)
        } catch {
            guard !(error is CancellationError) else { return }
            Notice(error: error).post()
        }
    }

    // MARK: Events

    func onRowAppear(_ row: SubscriberRowViewModel) {
        guard items.suffix(5).contains(where: { $0.id == row.id }) else {
            return
        }
        if error == nil {
            loadMore()
        }
    }

    private func didUpdateSearchText(_ searchText: String) {
        task?.cancel()
        // TODO: (kean) implement cancellation
        task = Task {
            try? await Task.sleep(for: .milliseconds(500))
            guard !Task.isCancelled else { return }
            await _refresh()
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
