import Foundation

public struct JustAsyncSequence<Element>: AsyncSequence {
    var producer: () async -> Element

    public init(_ output: Element) {
        self.init({ output })
    }

    public init(_ producer: @escaping () async -> Element) {
        self.producer = producer
    }

    public func makeAsyncIterator() -> Iterator {
        Iterator(producer: producer)
    }

    public struct Iterator: AsyncIteratorProtocol {
        var started = false
        let producer: () async -> Element

        public mutating func next() async -> Element? {
            guard !started else { return nil }

            started = true
            let result = await producer()
            return Task.isCancelled ? nil : result
        }
    }
}

public struct JustThrowingAsyncSequence<Element>: AsyncSequence {
    var producer: () async throws -> Element

    public init(_ error: Error) {
        self.init({ throw error })
    }

    public init(_ producer: @escaping () async throws -> Element) {
        self.producer = producer
    }

    public func makeAsyncIterator() -> Iterator {
        Iterator(producer: producer)
    }

    public struct Iterator: AsyncIteratorProtocol {
        var started = false
        let producer: () async throws -> Element

        public mutating func next() async throws -> Element? {
            guard !started else { return nil }

            started = true
            let result = try await producer()
            return Task.isCancelled ? nil : result
        }
    }
}
