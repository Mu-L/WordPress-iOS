import Foundation
@preconcurrency import Combine

public actor FileSystemDataStore<T>: DataStore where T: Identifiable, T.ID: Hashable & Sendable, T: Searchable, T: Codable, T: Sendable {

    private let fileManager: FileManager

    private let storageDirectory: URL

    init(fileManager: FileManager = .default) {
        self.fileManager = fileManager
        self.storageDirectory = fileManager.temporaryDirectory.appendingPathComponent("\(T.self)")
    }

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
        try createStorageDirectoryIfNeeded()

        return try allFilenames().compactMap {
            try read(itemAt: $0)
        }
    }

    public func delete(query: Query<T>) async throws {
        for try await list in listStream(query: query) {
            for item in list {
                try FileManager.default.removeItem(at: filepath(for: item))
            }
        }
    }

    public func store(_ data: [T]) async throws {
        for item in data {
            try write(item)
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

    private func read(itemAt url: URL) throws -> T? {
        try JSONDecoder().decode(T.self, from: Data(contentsOf: url))
    }

    private func write(_ item: T) throws {
        try createStorageDirectoryIfNeeded()
        try JSONEncoder().encode(item).write(to: filepath(for: item), options: .atomic)
    }

    private func allFilenames() throws -> [URL] {
        try createStorageDirectoryIfNeeded()

        return try fileManager
            .contentsOfDirectory(atPath: storageDirectory.path)
            .map { URL(fileURLWithPath: $0) }
    }

    private func filepath(for item: T) -> URL {
        storageDirectory.appendingPathComponent("\(item.id).json")
    }

    private func createStorageDirectoryIfNeeded() throws {
        try fileManager.createDirectory(at: storageDirectory, withIntermediateDirectories: true)
    }
}
