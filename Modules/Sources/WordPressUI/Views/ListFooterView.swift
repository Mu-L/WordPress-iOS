import SwiftUI

public struct ListFooterView: View {
    public enum State {
        case loading
        case failed(onRetry: () -> Void)
    }

    let state: State

    public init(state: State) {
        self.state = state
    }

    public var body: some View {
        Group {
            switch state {
            case .loading:
                ProgressView()
            case .failed(let onRetry):
                Button(action: onRetry) {
                    HStack {
                        Image(systemName: "exclamationmark.circle")
                        Text(AppLocalizedString("shared.button.retry", value: "Retry", comment: "A shared button title used in different contexts"))
                    }
                    .lineLimit(1)
                }
            }
        }
        .frame(maxWidth: .infinity)
        .listRowSeparator(.hidden)
    }
}
