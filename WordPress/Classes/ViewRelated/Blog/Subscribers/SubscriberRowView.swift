import SwiftUI
import WordPressUI
import WordPressKit

struct SubscriberRowView: View {
    let viewModel: SubscriberRowViewModel

    var body: some View {
        HStack(alignment: .center) {
            avatar.frame(width: 24, height: 24)
            (Text(viewModel.title) + Text(viewModel.details).foregroundColor(.secondary))
                .lineLimit(1)
        }
    }

    @ViewBuilder
    private var avatar: some View {
        switch viewModel.avatar {
        case .remote(let url):
            AvatarView(style: .single(url), diameter: 24, placeholderImage: Image("gravatar").resizable())
        case .email:
            Image(systemName: "envelope")
                .foregroundStyle(.tertiary)
        }
    }
}

@MainActor
final class SubscriberRowViewModel: Identifiable {
    let subscriberID: Int

    let title: String
    let avatar: Avatar
    let details: String

    enum Avatar {
        case remote(URL?)
        case email
    }

    init(_ subscriber: SubscribersServiceRemote.GetSubscribersResponse.Subscriber) {
        self.subscriberID = subscriber.subscriberID
        if subscriber.dotComUserID == 0 {
            self.avatar = .email
            self.title = subscriber.emailAddress ?? "–"
            self.details = ""
        } else {
            self.avatar = .remote(subscriber.avatar.flatMap(URL.init))
            self.title = subscriber.displayName ?? "–"
            self.details = subscriber.emailAddress.map { " (\($0))" } ?? ""
        }
    }
}
