import Foundation
import Combine
import WordPressUI

public actor InMemoryDataStore<T>: DataStore where T: Identifiable, T.ID: Hashable, T: Searchable {

    public var storage: [T.ID: T] = [:]
    public let updates: PassthroughSubject<Set<T.ID>, Never> = .init()

    deinit {
        updates.send(completion: .finished)
    }

    public func delete(query: Query<T>) async throws {
        var updated = Set<T.ID>()
        let result = try await list(query: query)
        result.forEach {
            if storage.removeValue(forKey: $0.id) != nil {
                updated.insert($0.id)
            }
        }

        if !updated.isEmpty {
            updates.send(updated)
        }
    }

    public func store(_ data: [T]) async throws {
        var updated = Set<T.ID>()
        data.forEach {
            updated.insert($0.id)
            self.storage[$0.id] = $0
        }

        if !updated.isEmpty {
            updates.send(updated)
        }
    }

    public func listStream(query: Query<T>) -> AsyncStream<Result<[T], Error>> {
        let stream = AsyncStream<Result<[T], Error>>.makeStream()

        let updatingTask = Task { [weak self] in
            var iter = await self?.updates.values.makeAsyncIterator()
            repeat {
                guard let self else { break }
                do {
                    let result = try await self.list(query: query)
                    stream.continuation.yield(.success(result))
                } catch {
                    stream.continuation.yield(.failure(error))
                }
            } while await iter?.next() != nil && !Task.isCancelled

            stream.continuation.finish()
        }

        stream.continuation.onTermination = {
            if case .cancelled = $0 {
                updatingTask.cancel()
            }
        }

        return stream.stream
    }

    public func list(query: Query<T>) async throws -> [T] {
        switch query {
        case .all:
            return Array(storage.values)
        case let .id(ids):
            return storage.reduce(into: []) {
                if ids.contains($1.key) {
                    $0.append($1.value)
                }
            }
        case let .search(keyword):
            let theKeyword = keyword.trimmingCharacters(in: .whitespacesAndNewlines)
            if theKeyword.isEmpty {
                return Array(storage.values)
            } else {
                return storage.values.search(theKeyword, using: \.searchString)
            }
        }
    }
}
