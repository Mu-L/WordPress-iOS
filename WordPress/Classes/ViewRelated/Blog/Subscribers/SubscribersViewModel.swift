import Foundation
import WordPressKit

@MainActor
final class SubscribersViewModel: ObservableObject {
    private let blog: Blog

    @Published private(set) var list: SubscribersListViewModel?
    @Published private(set) var isLoading = false
    @Published private(set) var error: Error?

    @Published var searchText = "" {
        didSet {
            guard oldValue != searchText else { return }
            didUpdateSearchText(searchText)
        }
    }

    private var task: Task<Void, Never>? {
        didSet { oldValue?.cancel() }
    }

    init(blog: Blog) {
        self.blog = blog
    }

    // TODO: (kean) how do we handle refresh for searchResponse?
    func refresh() async {
        isLoading = true
        defer { isLoading = false }
        do {
            self.list = try await SubscribersListViewModel(blog: blog)
        } catch {
            self.error = error
            if list != nil {
                Notice(error: error).post()
            }
            // TODO: (show) error correctly
        }

//        let response = SubscribersResponse(
//            blog: blog,
//            parameters: .init(search: searchText)
//        )
//        do {
//            let items = try await response.next()
//            self.response = response
//            self.items = items.map(SubscriberRowViewModel.init)
//        } catch {
//            guard !(error is CancellationError) else { return }
//            Notice(error: error).post()
//        }
    }

    private func didUpdateSearchText(_ searchText: String) {
        task = Task {
            if !searchText.isEmpty {
                try? await Task.sleep(for: .milliseconds(500))
            }
            guard !Task.isCancelled else { return }
            await refresh()
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
