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
        Group {
            if viewModel.subscribers.isEmpty {
                GeometryReader { proxy in
                    ScrollView { // Makes it compatible with refreshable()
                        stateView
                            .frame(width: proxy.size.width, height: proxy.size.height)
                    }
                }
            } else {
                List {
                    ForEach(viewModel.subscribers) { subscriber in
                        Text(subscriber.title)
                            .lineLimit(3)
                    }

                    footerView
                        .listRowSeparator(.hidden)
                }
                .listStyle(.plain)
            }
        }
        .task {
            await viewModel.loadMore()
        }

        // TODO: add refreshable
        // TODO: add "load more on paging"
    }

    @ViewBuilder
    private var stateView: some View {
        if viewModel.isLoading {
            ProgressView()
        } else if let error = viewModel.error {
            EmptyStateView.failure(error: error) {
                Task {
                    await viewModel.loadMore()
                }
            }
        } else {
            EmptyStateView(Strings.empty, systemImage: "envelope")
        }
    }

    @ViewBuilder
    private var footerView: some View {
        if viewModel.currentPage > 1 {
            if viewModel.isLoading {
                ProgressView()
                    .frame(maxWidth: .infinity)
            } else if let error = viewModel.error {
                // TODO: update the UI
                Button {
                    Task {
                        await viewModel.loadMore()
                    }
                } label: {
                    Label(SharedStrings.Button.retry, systemImage: "exclamationmark.circle")
                }
            }
        }
    }
}

private enum Strings {
    static let title = NSLocalizedString("subscribers.title", value: "Subscribers", comment: "Screen title")
    static let empty = NSLocalizedString("subscribers.empty", value: "No Subscribers", comment: "Empty state view title")
}
