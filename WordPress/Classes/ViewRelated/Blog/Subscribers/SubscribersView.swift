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
            .onAppear {
                viewModel.loadMore()
            }
    }

    @ViewBuilder
    private var contentView: some View {
        if viewModel.items.isEmpty {
            stateView
        } else {
            list
        }
    }

    @ViewBuilder
    private var list: some View {
        List {
            ForEach(viewModel.items) { subscriber in
                Text(subscriber.title)
                    .lineLimit(3)
                    .onAppear {
                        viewModel.onRowAppear(subscriber)
                    }
            }
            footerView
                .listRowSeparator(.hidden)
        }
        .listStyle(.plain)
        .refreshable {
            await viewModel.refresh()
        }
    }

    @ViewBuilder
    private var stateView: some View {
        if viewModel.isLoading {
            ProgressView()
        } else if let error = viewModel.error {
            EmptyStateView.failure(error: error) {
                viewModel.loadMore()
            }
        } else {
            EmptyStateView(Strings.empty, systemImage: "envelope")
        }
    }

    @ViewBuilder
    private var footerView: some View {
        if viewModel.currentPage > 1 {
            if viewModel.isLoading {
                ListFooterView(.loading)
            } else if viewModel.error != nil {
                ListFooterView(.failure).onRetry {
                    viewModel.loadMore()
                }
            }
        }
    }
}

private enum Strings {
    static let title = NSLocalizedString("subscribers.title", value: "Subscribers", comment: "Screen title")
    static let empty = NSLocalizedString("subscribers.empty", value: "No Subscribers", comment: "Empty state view title")
}
