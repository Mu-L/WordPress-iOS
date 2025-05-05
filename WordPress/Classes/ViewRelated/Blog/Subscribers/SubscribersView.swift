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

@MainActor
private struct SubscribersView: View {
    @ObservedObject var viewModel: SubscribersViewModel

    var body: some View {
        contentView
            .searchable(text: $viewModel.searchText)
            .task {
                await viewModel.refresh()
            }
    }

    @ViewBuilder
    private var contentView: some View {
        if let list = viewModel.list {
            SubscribersListView(viewModel: list)
                .refreshable {
                    await viewModel.refresh()
                }
        } else {
            stateView
        }
    }

    @ViewBuilder
    private var stateView: some View {
        if viewModel.isLoading {
            ProgressView()
        } else if let error = viewModel.error {
            EmptyStateView.failure(error: error) {
                Task {
                    await viewModel.refresh()
                }
            }
        } else {
            EmptyStateView(Strings.empty, systemImage: "envelope")
        }
    }
}

private struct SubscribersListView: View {
    @ObservedObject var viewModel: SubscribersListViewModel

    var body: some View {
        List {
            ForEach(viewModel.items) { item in
                Text(item.title)
                    .onAppear {
                        viewModel.onRowAppear(item)
                    }
            }
            footerView
        }
        .listStyle(.plain)
    }

    @ViewBuilder
    private var footerView: some View {
        if viewModel.isLoading {
            ListFooterView(.loading)
        } else if viewModel.error != nil {
            ListFooterView(.failure).onRetry {
                viewModel.loadMore()
            }
        }
    }
}

private enum Strings {
    static let title = NSLocalizedString("subscribers.title", value: "Subscribers", comment: "Screen title")
    static let empty = NSLocalizedString("subscribers.empty", value: "No Subscribers", comment: "Empty state view title")
}
