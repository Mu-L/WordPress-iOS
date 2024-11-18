import SwiftUI

@MainActor
class UserDetailViewModel: ObservableObject {
    private let user: DisplayUser
    private let userService: UserServiceProtocol
    private let applicationTokenListDataProvider: ApplicationTokenListDataProvider

    @Published
    private(set) var applicationTokens: [ApplicationTokenItem] = []

    @Published
    private(set) var currentUserCanModifyUsers: Bool = false

    @Published
    private(set) var isLoadingCurrentUser: Bool = false

    init(user: DisplayUser, userService: UserServiceProtocol, applicationTokenListDataProvider: ApplicationTokenListDataProvider) {
        self.user = user
        self.userService = userService
        self.applicationTokenListDataProvider = applicationTokenListDataProvider
    }

    func onAppear() async {
        isLoadingCurrentUser = true
        defer { isLoadingCurrentUser = false}

        currentUserCanModifyUsers = await userService.isCurrentUserCapableOf("edit_users")

        // The capability of listing application passwords is "list_app_passwords". But it's not returned in the `user/me`
        // REST API endpoint, even though the current user can list application passwords.
        // We'll just send the REST API anyways and ignore the error.
        let applicationTokens = (try? await applicationTokenListDataProvider.loadApplicationTokens(userId: user.id)) ?? []
        self.applicationTokens = applicationTokens.sorted { lhs, rhs in
            // The most recently used/created is placed at the top.
            (lhs.lastUsed ?? .distantPast, lhs.createdAt) > (rhs.lastUsed ?? .distantPast, rhs.createdAt)
        }
    }
}
