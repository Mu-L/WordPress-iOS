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

    private var task: Task<Void, Never>? {
        didSet { oldValue?.cancel() }
    }

    init(blog: Blog) {
        self.blog = blog
        self.response = SubscribersPaginatedResponse(blog: blog)
    }

    func loadMore() {
        guard response.hasMore && !isLoading else {
            return
        }
        isLoading = true
        error = nil
        task = Task {
            // TODO: (kean) simplify this using `Result` type
            do {
                let items = try await response.next()
                self.items += items.map(SubscriberRowViewModel.init)
            } catch {
                guard !(error is CancellationError) else { return }
                self.error = error
            }
            if !Task.isCancelled {
                isLoading = false
            }
        }
    }

    // TODO: (kean) how do we handle refresh for searchResponse?
    func refresh() async {
        task = Task {
            await reload()
        }
        await task?.value
    }

    private func reload() async {
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

    func onRowAppear(_ row: SubscriberRowViewModel) {
        guard items.suffix(5).contains(where: { $0.id == row.id }) else {
            return
        }
        if error == nil {
            loadMore()
        }
    }

    private func didUpdateSearchText(_ searchText: String) {
        task = Task {
            if !searchText.isEmpty {
                try? await Task.sleep(for: .milliseconds(500))
            }
            guard !Task.isCancelled else { return }
            await reload()
        }
    }
}

@MainActor
final class SubscriberRowViewModel: Identifiable {
    let subscriptionID: Int
    let title: String

    init(_ subscriber: RemoteSubscriber) {
        self.subscriptionID = subscriber.subscriptionID
        self.title = subscriber.emailAddress ?? "–"
    }
}
