import Foundation
import Combine

public extension AsyncSequence {
    var publisher: AnyPublisher<Element, any Error> {
        precondition(!(self is AsyncStream<Element>) && !(self is AsyncThrowingStream<Element, Error>), "Use sharedPublisher for AsyncStream and AsyncThrowingStream")

        return StreamPublisher(sequence: self).eraseToAnyPublisher()
    }

    var sharedPublisher: Publishers.Share<AnyPublisher<Element, any Error>> {
        StreamPublisher(sequence: self).eraseToAnyPublisher().share()
    }
}

public extension AsyncStream {
    @available(*, deprecated, message: "Use sharedPublisher for AsyncStream and AsyncThrowingStream")
    var publisher: AnyPublisher<Element, any Error> {
        fatalError("Use sharedPublisher for AsyncStream and AsyncThrowingStream")
    }
}

public extension AsyncThrowingStream {
    @available(*, deprecated, message: "Use sharedPublisher for AsyncStream and AsyncThrowingStream")
    var publisher: AnyPublisher<Element, any Error> {
        fatalError("Use sharedPublisher for AsyncStream and AsyncThrowingStream")
    }
}

class StreamPublisher<Sequence: AsyncSequence>: Publisher {

    typealias Output = Sequence.Element
    typealias Failure = Error

    let sequence: Sequence

    init(sequence: Sequence) {
        self.sequence = sequence
    }

    func receive<S: Subscriber>(subscriber: S) where S.Input == Output, S.Failure == Failure {
        let subscription = Subscription(sequence: sequence, subscriber: subscriber)
        subscriber.receive(subscription: subscription)
    }

    class Subscription<S: Subscriber>: Combine.Subscription where S.Input == Output, S.Failure == Failure {
        let sequence: Sequence

        var subscriber: S?
        var task: Task<Void, Never>?
        var outputSent: Int = 0

        init(sequence: Sequence, subscriber: S) {
            self.sequence = sequence
            self.subscriber = subscriber
        }

        func request(_ demand: Subscribers.Demand) {
            task = Task {
                do {
                    if let max = demand.max {
                        for try await element in sequence.prefix(max) {
                            try Task.checkCancellation()

                            _ = subscriber?.receive(element)
                        }
                    } else {
                        for try await element in sequence {
                            try Task.checkCancellation()

                            _ = subscriber?.receive(element)
                        }
                    }
                    subscriber?.receive(completion: .finished)
                } catch {
                    subscriber?.receive(completion: .failure(error))
                }
            }
        }

        func cancel() {
            task?.cancel()
            task = nil
            subscriber = nil
        }
    }
}
