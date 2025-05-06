import UIKit
import SwiftUI
import WordPressUI
import WordPressKit

final class SubscribersViewController: UIHostingController<AnyView> {
    private let viewModel: SubscribersViewModel

    init(blog: Blog) {
        self.viewModel = SubscribersViewModel(blog: blog)
        super.init(rootView: AnyView(SubscribersView(viewModel: viewModel)))
        self.title = Strings.title
    }

    required dynamic init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

// TODO:
// - disable `refreshable` for search
// - switch between different List views for search
private struct SubscribersView: View {
    @ObservedObject var viewModel: SubscribersViewModel

    var body: some View {
        Group {
            if !viewModel.searchText.isEmpty {
                SubscribersSearchView(viewModel: viewModel)
            } else {
                SubscribersListView(viewModel: viewModel)
            }
        }
        .searchable(text: $viewModel.searchText)
    }
}

private struct SubscribersListView: View {
    @ObservedObject var viewModel: SubscribersViewModel

    var body: some View {
        List {
            if let response = viewModel.response {
                SubscribersPaginatedForEach(response: response)
            }
        }
        .listStyle(.plain)
        .overlay {
            if let response = viewModel.response {
                if response.isEmpty {
                    EmptyStateView(Strings.empty, systemImage: "envelope")
                }
            } else if viewModel.isLoading {
                ProgressView()
            } else if let error = viewModel.error {
                EmptyStateView.failure(error: error) {
                    Task { await viewModel.refresh() }
                }
            }
        }
        .task(id: viewModel.parameters) {
            await viewModel.refresh()
        }
        .refreshable {
            await viewModel.refresh()
        }
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                menu
            }
        }
    }

    private typealias FilterSubscriptionType = PeopleServiceRemote.SubscribersParameters.FilterSubscriptionType

    // TODO: (kean) add l10n
    private var menu: some View {
        Menu {
            Section("Subcription Type") {
                Picker("Subcription Type", selection: $viewModel.parameters.subscriptionTypeFilter) {
                    Text("All Subscriptions").tag(Optional<FilterSubscriptionType>.none)
                    ForEach(FilterSubscriptionType.allCases, id: \.self) { item in
                        Text(item.rawValue).tag(item)
                    }
                }
            }
        } label: {
            Image(systemName: "ellipsis")
        }
    }
}

private struct SubscribersSearchView: View {
    @ObservedObject var viewModel: SubscribersViewModel

    var body: some View {
        List {
            if let response = viewModel.searchResponse {
                SubscribersPaginatedForEach(response: response)
            }
        }
        .listStyle(.plain)
        .overlay {
            if let response = viewModel.searchResponse, response.isEmpty {
                EmptyStateView.search()
            } else if let error = viewModel.searchError {
                EmptyStateView.failure(error: error)
            }
        }
        .task(id: viewModel.searchText) {
            await viewModel.search()
        }
    }
}

private struct SubscribersPaginatedForEach: View {
    @ObservedObject var response: SubscribersPaginatedResponse

    var body: some View {
        ForEach(response.items) { item in
            Text(item.title)
                .onAppear { response.onRowAppear(item) }
        }
        if response.isLoading {
            ListFooterView(.loading)
        } else if response.error != nil {
            ListFooterView(.failure).onRetry {
                response.loadMore()
            }
        }
    }
}

private enum Strings {
    static let title = NSLocalizedString("subscribers.title", value: "Subscribers", comment: "Screen title")
    static let empty = NSLocalizedString("subscribers.empty", value: "No Subscribers", comment: "Empty state view title")
}
