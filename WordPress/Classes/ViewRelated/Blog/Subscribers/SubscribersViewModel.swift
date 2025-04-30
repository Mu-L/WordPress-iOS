import Foundation

final class SubscribersViewModel: ObservableObject {
    private let blog: Blog

    init(blog: Blog) {
        self.blog = blog
    }
}
