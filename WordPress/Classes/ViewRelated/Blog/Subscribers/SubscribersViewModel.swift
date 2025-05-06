import Foundation
import WordPressKit

@MainActor
final class SubscribersViewModel: ObservableObject {
    private let blog: Blog

    @Published private(set) var response: SubscribersPaginatedResponse?
    @Published private(set) var searchViewModel: SubscribersSearchViewModel?
    @Published private(set) var isLoading = false
    @Published private(set) var error: Error?

    @Published var searchText = "" {
        didSet {
            guard oldValue != searchText else { return }
            if searchText.isEmpty {
                searchViewModel = nil
            } else {
                searchViewModel = searchViewModel ?? SubscribersSearchViewModel(blog: blog)
                searchViewModel?.search(searchText)
            }
        }
    }

    init(blog: Blog) {
        self.blog = blog
    }

    func refresh() async {
        error = nil
        isLoading = true
        defer { isLoading = false }
        do {
            response = try await SubscribersPaginatedResponse(blog: blog)
        } catch {
            self.error = error
            if response != nil {
                Notice(error: error).post()
            }
        }
    }
}

@MainActor
final class SubscribersSearchViewModel: ObservableObject {
    private let blog: Blog

    @Published private(set) var response: SubscribersPaginatedResponse?
    @Published private(set) var error: Error?

    private var searchTask: Task<Void, Never>?

    init(blog: Blog) {
        self.blog = blog
    }

    func search(_ searchText: String) {
        error = nil
        searchTask?.cancel()
        searchTask = Task {
            try? await Task.sleep(for: .milliseconds(500))
            guard !Task.isCancelled else { return }
            do {
                response = try await SubscribersPaginatedResponse(blog: blog, parameters: .init(search: searchText))
            } catch {
                self.error = error
                response = nil
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
        self.title = subscriber.emailAddress ?? "–"
    }
}
