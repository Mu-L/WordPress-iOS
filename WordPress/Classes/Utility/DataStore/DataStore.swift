import Foundation
import WordPressShared

/// An abstraction of local data storage, with CRUD operations.
public protocol DataStore<T>: Actor {
    associatedtype T: Identifiable & Sendable where T.ID: Sendable

    func list(query: DataStoreQuery<T>) async throws -> [T]
    func delete(query: DataStoreQuery<T>) async throws
    func store(_ data: [T]) async throws

    /// An AsyncStream that produces up-to-date results for the given query.
    ///
    /// The `AsyncStream` should not finish as long as the `DataStore` remains alive and valid.
    func listStream(query: DataStoreQuery<T>) -> AsyncStream<Result<[T], Error>>
}

public struct DataStoreQuery<T: Identifiable & Sendable>: Sendable where T.ID: Sendable {
    public indirect enum Filter: Sendable {
        case identifier(Set<T.ID>)
        case closure(@Sendable (T) -> Bool)
        case and(lhs: Filter, rhs: Filter)
        case or(lhs: Filter, rhs: Filter)

        func evaluate(on value: T) -> Bool {
            switch self {
            case let .identifier(ids):
                ids.contains(value.id)
            case let .closure(closure):
                closure(value)
            case let .and(lhs, rhs):
                lhs.evaluate(on: value) && rhs.evaluate(on: value)
            case let .or(lhs, rhs):
                lhs.evaluate(on: value) || rhs.evaluate(on: value)
            }
        }
    }

    var filter: Filter?
    var sortBy: [SortDescriptor<T>] = []

    public func perform(on data: any Sequence<T>) -> [T] {
        var result: any Sequence<T> = data
        if let filter {
            result = result.filter { filter.evaluate(on: $0) }
        }
        return result.sorted(using: sortBy)
    }

    public static var all: Self { .init() }

    public static func identifier(in ids: Set<T.ID>) -> Self {
        .init(filter: .identifier(ids))
    }

    public static func search(_ query: String, minScore: Double = 0.7, transform: @escaping (T) -> String) -> Self {
        let term = StringRankedSearch(searchTerm: query)
        return .init(filter: .closure { term.score(for: transform($0)) >= minScore })
    }
}
