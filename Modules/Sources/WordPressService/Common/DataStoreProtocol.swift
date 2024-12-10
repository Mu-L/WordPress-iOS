import Foundation

/// An abstraction of local data storage, with CRUD operations.
public protocol DataStore<T>: Actor where T: Identifiable & Sendable & Searchable {
    associatedtype T: Identifiable & Sendable & Searchable

    func list(query: Query<T>) async throws -> [T]
    func delete(query: Query<T>) async throws
    func store(_ data: [T]) async throws

    /// An AsyncStream that produces up-to-date results for the given query.
    ///
    /// The `AsyncStream` should not finish as long as the `DataStore` remains alive and valid.
    func listStream(query: Query<T>) -> AsyncThrowingStream<[T], Error>
}
