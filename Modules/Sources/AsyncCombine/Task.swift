import Foundation
import Combine

extension Task where Failure == Never {
    var stream: AsyncStream<Success> {
        AsyncStream(unfolding: { await self.value }, onCancel: cancel)
    }

    public var publisher: Publishers.Share<AnyPublisher<Success, Error>> {
        stream.sharedPublisher
    }
}

extension Task where Failure == Error {
    var stream: AsyncThrowingStream<Success, Failure> {
        let builder: (AsyncThrowingStream<Success, Failure>.Continuation) -> Void = { continuation in
            Task<Void, Never> {
                do {
                    let output = try await self.value
                    continuation.yield(output)
                    continuation.finish()
                } catch {
                    continuation.finish(throwing: error)
                }
            }
            continuation.onTermination = {
                if case .cancelled = $0 {
                    self.cancel()
                }
            }
        }
        return AsyncThrowingStream(Success.self, builder)
    }
    
    public var publisher: Publishers.Share<AnyPublisher<Success, Error>> {
        stream.sharedPublisher
    }
}
