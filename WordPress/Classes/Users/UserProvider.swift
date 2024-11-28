import Foundation
import Combine

public protocol Searchable {
    var searchString: String { get }
}

public enum Query<T>: Equatable where T: Identifiable, T: Searchable {
    case all
    case id(Set<T.ID>)
    case search(String)
}

public protocol UserServiceProtocol: Actor {
    var dataStore: any DataStore<DisplayUser> { get }

    func fetchUsers() async throws

    func isCurrentUserCapableOf(_ capability: String) async -> Bool

    func setNewPassword(id: Int32, newPassword: String) async throws

    func deleteUser(id: Int32, reassigningPostsTo newUserId: Int32) async throws
}

actor MockUserProvider: UserServiceProtocol {
    var dataStore: any DataStore<DisplayUser> = InMemoryDataStore<DisplayUser>()

    enum Scenario {
        case infinitLoading
        case dummyData
        case error
    }

    var scenario: Scenario

    nonisolated let usersUpdates: AsyncStream<[DisplayUser]>
    private let usersUpdatesContinuation: AsyncStream<[DisplayUser]>.Continuation

    private(set) var users: [DisplayUser]? {
        didSet {
            if let users {
                usersUpdatesContinuation.yield(users)
            }
        }
    }

    init(scenario: Scenario = .dummyData) {
        self.scenario = scenario
        (usersUpdates, usersUpdatesContinuation) = AsyncStream<[DisplayUser]>.makeStream()
    }

    func fetchUsers() async throws {
        switch scenario {
        case .infinitLoading:
            // Do nothing
            try await Task.sleep(for: .seconds(24 * 60 * 60))
        case .dummyData:
            let dummyDataUrl = URL(string: "https://my.api.mockaroo.com/users.json?key=067c9730")!
            let response = try await URLSession.shared.data(from: dummyDataUrl)
            let users = try JSONDecoder().decode([DisplayUser].self, from: response.0)
            try await dataStore.delete(query: Query<DisplayUser>.all)
            try await dataStore.store(users)
        case .error:
            throw URLError(.timedOut)
        }
    }

    func isCurrentUserCapableOf(_ capability: String) async -> Bool {
        true
    }

    func setNewPassword(id: Int32, newPassword: String) async throws {
        // Not used in Preview
    }

    func deleteUser(id: Int32, reassigningPostsTo newUserId: Int32) async throws {
        // Not used in Preview
    }
}
