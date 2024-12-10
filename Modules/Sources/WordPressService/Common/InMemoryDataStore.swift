import Foundation
@preconcurrency import Combine
import WordPressShared

/// A `DataStore` type that stores data in memory.
public actor InMemoryDataStore<T>: DataStore where T: Identifiable & Searchable & Sendable, T.ID: Hashable & Sendable {
    /// A `Dictionary` to store the data in memory.
    var storage: [T.ID: T] = [:]

    /// A publisher for sending and subscribing data changes.
    ///
    /// The publisher emits events when data changes, with identifiers of changed models.
    ///
    /// The publisher does not complete as long as the `InMemoryDataStore` remains alive and valid.
    var updates: PassthroughSubject<Set<T.ID>, Never> = PassthroughSubject()

    deinit {
        updates.send(completion: .finished)
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

    public func listStream(query: Query<T>) -> AsyncThrowingStream<[T], Error> {
        let stream = AsyncThrowingStream<[T], Error>.makeStream()

        let updatingTask = Task {
            var iter = self.updates.values.makeAsyncIterator()
            repeat {
                do {
                    let result = try await self.list(query: query)
                    stream.continuation.yield(with: .success(result))
                } catch {
                    stream.continuation.yield(with: .failure(error))
                }
            } while await iter.next() != nil && !Task.isCancelled

            stream.continuation.finish()
        }

        stream.continuation.onTermination = {
            if case .cancelled = $0 {
                updatingTask.cancel()
            }
        }

        return stream.stream
    }
}
