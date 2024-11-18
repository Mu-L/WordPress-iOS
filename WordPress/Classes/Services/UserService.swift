import Foundation
import Combine
import WordPressAPI
import WordPressUI

protocol ObjectCache<Cacheable>: Actor {

    associatedtype Cacheable: (Identifiable & Sendable)

    func get(_ id: Cacheable.ID) -> Cacheable?
    func store(_ object: Cacheable)
    func store(_ objects: [Cacheable])
    func all() -> [Cacheable]
    func invalidate(_ id: Cacheable.ID)
}

actor InMemoryCache<Cacheable: Identifiable & Sendable>: ObjectCache {

    private var objects: [Cacheable.ID: Cacheable] = [:]

    func get(_ id: Cacheable.ID) -> Cacheable? {
        objects[id]
    }

    func store(_ object: Cacheable) {
        objects[object.id] = object
    }

    func store(_ newObjects: [Cacheable]) {
        for object in newObjects {
            objects[object.id]  = object
        }
    }

    func all() -> [Cacheable] {
        [Cacheable](objects.values)
    }

    func invalidate(_ id: Cacheable.ID) {
        self.objects.removeValue(forKey: id)
    }
}

/// UserService is responsible for fetching user acounts via the .org REST API – it's the replacement for `UsersService` (the XMLRPC-based approach)
///
actor UserService: UserServiceProtocol {
    private let client: WordPressClient

    private let cache: any ObjectCache<DisplayUser>

    private var currentUser: UserWithEditContext?

    private var tasks: [Task<(), any Error>] = []

    init(client: WordPressClient, cache: any ObjectCache<DisplayUser>) {
        self.client = client
        self.cache = cache
    }

    deinit {
        for task in tasks {
            task.cancel()
        }
    }

    func fetchPaginatedUsers() -> AsyncThrowingStream<[DisplayUser], Error> {
        AsyncThrowingStream { continuation in
            let handle = Task {
                let all = await self.cache.all()

                continuation.yield(all)

                for try await page in await self.client.api
                    .users
                    .sequenceWithEditContext(params: UserListParams(perPage: 5))
                    .map({ $0.compactMap(DisplayUser.init) }) {
                    await self.cache.store(page)
                    continuation.yield(page)
                }

                continuation.finish()
            }

            self.tasks.append(handle)
        }
    }

    func isCurrentUserCapableOf(_ capability: String) async throws -> Bool {
        let currentUser: UserWithEditContext
        if let cached = self.currentUser {
            currentUser = cached
        } else {
            currentUser = try await self.client.api.users.retrieveMeWithEditContext().data
            self.currentUser = currentUser
        }

        return currentUser.capabilities.keys.contains(capability)
    }

    func deleteUser(id: Int32, reassigningPostsTo newUserId: Int32) async throws {
        let result = try await client.api.users.delete(
            userId: id,
            params: UserDeleteParams(reassign: newUserId)
        ).data

        // Remove the deleted user from the cached users list.
        if result.deleted {
            await cache.invalidate(id)
        }
    }

    func setNewPassword(id: Int32, newPassword: String) async throws {
        _ = try await client.api.users.update(
            userId: Int32(id),
            params: UserUpdateParams(password: newPassword)
        )
    }
}

private extension DisplayUser {
    init?(user: UserWithEditContext) {
        guard let role = user.roles.first else {
            return nil
        }

        self.init(
            id: user.id,
            handle: user.slug,
            username: user.username,
            firstName: user.firstName,
            lastName: user.lastName,
            displayName: user.name,
            profilePhotoUrl: Self.profilePhotoUrl(for: user),
            role: role,
            emailAddress: user.email,
            websiteUrl: user.link,
            biography: user.description
        )
    }

    static func profilePhotoUrl(for user: UserWithEditContext) -> URL? {
        // The key is the size of the avatar. Get the largetst one, which is 96x96px.
        // https://github.com/WordPress/wordpress-develop/blob/6.6.2/src/wp-includes/rest-api.php#L1253-L1260
        guard let url = user.avatarUrls?
            .max(by: { $0.key.compare($1.key, options: .numeric) == .orderedAscending } )?
            .value
        else { return nil }

        return URL(string: url)
    }
}
