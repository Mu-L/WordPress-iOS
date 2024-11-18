import Foundation
import Combine

public protocol UserServiceProtocol: Actor {
    func fetchPaginatedUsers() -> AsyncThrowingStream<[DisplayUser], Error>

    func isCurrentUserCapableOf(_ capability: String) async throws -> Bool

    func setNewPassword(id: Int32, newPassword: String) async throws

    func deleteUser(id: Int32, reassigningPostsTo newUserId: Int32) async throws
}
//
//package actor MockUserProvider: UserServiceProtocol {
//
//    enum Scenario {
//        case infinitLoading
//        case dummyData
//        case error
//    }
//
//    var scenario: Scenario
//
//    init(scenario: Scenario = .dummyData) {
//        self.scenario = scenario
//    }
//
//    public func fetchUsers() async throws -> any AsyncSequence {
//        [DisplayUser]().async
//    }
//
//
//    package func fetchUsers() async throws -> [DisplayUser] {
//        switch scenario {
//        case .infinitLoading:
//            // Do nothing
//            try await Task.sleep(for: .seconds(24 * 60 * 60))
//            return []
//        case .dummyData:
//            let dummyDataUrl = URL(string: "https://my.api.mockaroo.com/users.json?key=067c9730")!
//            let response = try await URLSession.shared.data(from: dummyDataUrl)
//            let users = try JSONDecoder().decode([DisplayUser].self, from: response.0)
//            return users
//        case .error:
//            throw URLError(.timedOut)
//        }
//    }
//
//    package func isCurrentUserCapableOf(_ capability: String) async throws -> Bool {
//        true
//    }
//
//    package func setNewPassword(id: Int32, newPassword: String) async throws {
//        // Not used in Preview
//    }
//
//    package func deleteUser(id: Int32, reassigningPostsTo newUserId: Int32) async throws {
//        // Not used in Preview
//    }
//}
