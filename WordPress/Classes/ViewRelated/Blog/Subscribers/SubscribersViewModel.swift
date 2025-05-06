import Foundation
import WordPressKit

@MainActor
final class SubscribersViewModel: ObservableObject {
    private let blog: Blog

    @Published var parameters = PeopleServiceRemote.SubscribersParameters()
    @Published var searchText = ""

    @Published private(set) var isLoading = false
    @Published private(set) var response: SubscribersPaginatedResponse?
    @Published private(set) var error: Error?
    @Published private(set) var searchResponse: SubscribersPaginatedResponse?
    @Published private(set) var searchError: Error?

    init(blog: Blog) {
        self.blog = blog
    }

    func refresh() async {
        error = nil
        isLoading = true
        do {
            let response = try await SubscribersPaginatedResponse(blog: blog, parameters: parameters)
            guard !Task.isCancelled else { return }
            self.isLoading = false
            self.response = response
        } catch {
            guard !Task.isCancelled else { return }
            self.isLoading = false
            self.error = error
            if response != nil {
                Notice(error: error).post()
            }
        }
    }

    // TODO: (kean) fix cancellation here and fix how we narrow search somhow
    func search() async {
        guard !searchText.isEmpty else {
            searchResponse = nil
            searchError = nil
            return
        }
        searchError = nil
        do {
            try await Task.sleep(for: .milliseconds(500))
            let response = try await SubscribersPaginatedResponse(blog: blog, parameters: parameters, search: searchText)
            guard !Task.isCancelled else { return }
            searchResponse = response
        } catch {
            guard !Task.isCancelled else { return }
            searchResponse = nil
            searchError = error
        }
    }
}

// TODO: (kean) move this to framework

extension PeopleServiceRemote.SubscribersParameters.FilterSubscriptionType {
    static var allCases: [PeopleServiceRemote.SubscribersParameters.FilterSubscriptionType] {
        [
            .blocked, .email, .reader, .unconfirmed
        ]
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
