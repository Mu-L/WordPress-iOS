import UIKit
import SwiftUI
import WordPressUI

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

private struct SubscribersView: View {
    @ObservedObject var viewModel: SubscribersViewModel

    var body: some View {
        List {
            if let searchViewModel = viewModel.searchViewModel {
                SubscribersSearchResultsView(viewModel: searchViewModel)
            } else if let response = viewModel.response {
                SubscribersPaginatedForEach(response: response)
            }
        }
        .listStyle(.plain)
        .overlay {
            if let searchViewModel = viewModel.searchViewModel {
                SubscribersSearchStateView(viewModel: searchViewModel)
            } else {
                SubscribersStateView(viewModel: viewModel)
            }
        }
        .searchable(text: $viewModel.searchText)
        .task { await viewModel.refresh() }
        .refreshable { await viewModel.refresh() }
    }
}

private struct SubscribersStateView: View {
    @ObservedObject var viewModel: SubscribersViewModel

    var body: some View {
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
}

private struct SubscribersSearchResultsView: View {
    @ObservedObject var viewModel: SubscribersSearchViewModel

    var body: some View {
        if let response = viewModel.response {
            SubscribersPaginatedForEach(response: response)
        }
    }
}

private struct SubscribersSearchStateView: View {
    @ObservedObject var viewModel: SubscribersSearchViewModel

    var body: some View {
        if let response = viewModel.response, response.isEmpty {
            EmptyStateView.search()
        } else if let error = viewModel.error {
            EmptyStateView.failure(error: error)
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
