import XCTest
import Combine

@testable import AsyncCombine

class SharedPublisherTests: XCTestCase {
    var cancellables: Set<AnyCancellable> = []

    override func tearDown() {
        super.tearDown()
        cancellables.removeAll()
    }

    /// Create publishers that emit elements in [0, 1, 2, 3, 4], with 0.1 seconds interval.
    ///
    /// The first one is publisher implemented by this library, and the second one is the Timer publisher from Foundation.
    ///
    /// The Timer publisher is a `shared` publisher, where one upstream publisher broadcasts outputs to all subscribers.
    /// This publisher instance is created to match `AsyncStream`'s behaviour where one stream instance emits elements to
    /// all its `await`ers.
    func createComparisonPublishers() -> (stream: AnyPublisher<Int, Error>, timer: AnyPublisher<Int, Never>) {
        let stream = Counter(start: 0, end: 4, interval: .milliseconds(100))
            .sharedPublisher
            .eraseToAnyPublisher()

        let timer = Timer.publish(every: 0.1, on: .main, in: .default)
            .autoconnect()
            .prefix(5)
            .scan(-1) { counter, _ in counter + 1 }
            .share() // IMPORTANT
            .eraseToAnyPublisher()

        return (stream, timer)
    }

    func subscribAtTheSameTime<E: Error>(publisher: AnyPublisher<Int, E>, line: UInt = #line) {
        let expectation = XCTestExpectation(description: "Subscribers complete")
        expectation.expectedFulfillmentCount = 2
        var first: [Int] = []
        var second: [Int] = []

        publisher.sink(
            receiveCompletion: { _ in expectation.fulfill() },
            receiveValue: { value in
                first.append(value)
            }
        ).store(in: &cancellables)

        publisher.sink(
            receiveCompletion: { _ in expectation.fulfill() },
            receiveValue: { value in
                second.append(value)
            }
        ).store(in: &cancellables)

        wait(for: [expectation], timeout: 1)

        XCTAssertEqual(first, [0, 1, 2, 3, 4], "The first subscriber receives the full sequence", line: line)
        XCTAssertEqual(second, [0, 1, 2, 3, 4], "The second subscriber receives the full sequence", line: line)
    }

    func testSubscribAtTheSameTime() {
        let (stream, _) = createComparisonPublishers()
        subscribAtTheSameTime(publisher: stream)
    }

    func testSubscribAtTheSameTime_Reference() {
        let (_, timer) = createComparisonPublishers()
        subscribAtTheSameTime(publisher: timer)
    }

    func singleSubscriptionWithDelay<E: Error>(publisher: AnyPublisher<Int, E>, line: UInt = #line) {
        let expectation = XCTestExpectation(description: "Subscribers complete")
        var received: [Int] = []

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            publisher.sink(
                receiveCompletion: { _ in expectation.fulfill() },
                receiveValue: { value in
                    received.append(value)
                }
            ).store(in: &self.cancellables)
        }

        wait(for: [expectation], timeout: 1)

        XCTAssertEqual(received, [0, 1, 2, 3, 4], "Receives the full sequence", line: line)
    }

    func testSingleSubscriptionWithDelay() {
        let (stream, _) = createComparisonPublishers()
        singleSubscriptionWithDelay(publisher: stream)
    }

    func testSingleSubscriptionWithDelay_Reference() {
        let (_, timer) = createComparisonPublishers()
        singleSubscriptionWithDelay(publisher: timer)
    }

    func multiSubscriptionWithOneDelay<E: Error>(publisher: AnyPublisher<Int, E>, line: UInt = #line) {
        let expectation = XCTestExpectation(description: "Subscribers complete")
        expectation.expectedFulfillmentCount = 2
        var first: [Int] = []
        var second: [Int] = []

        publisher.sink(
            receiveCompletion: { _ in expectation.fulfill() },
            receiveValue: { value in
                first.append(value)
            }
        ).store(in: &cancellables)

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            publisher.sink(
                receiveCompletion: { _ in expectation.fulfill() },
                receiveValue: { value in
                    second.append(value)
                }
            ).store(in: &self.cancellables)
        }

        wait(for: [expectation], timeout: 1)

        XCTAssertEqual(first, [0, 1, 2, 3, 4], "The first subscriber receives the full sequence", line: line)
        XCTAssertGreaterThan(first.count, second.count, "The second subscriber only recieves a subset of the full sequence", line: line)
        XCTAssert(first.ends(with: second), "The second subscriber receives the tail of the full sequence", line: line)
    }

    func testMultiSubscriptionWithOneDelay() {
        let (stream, _) = createComparisonPublishers()
        multiSubscriptionWithOneDelay(publisher: stream)
    }

    func testMultiSubscriptionWithOneDelay_Reference() {
        let (_, timer) = createComparisonPublishers()
        multiSubscriptionWithOneDelay(publisher: timer)
    }

    func multiSubscriptionWithMultiDelay<E: Error>(publisher: AnyPublisher<Int, E>, line: UInt = #line) {
        let expectation = XCTestExpectation(description: "Subscribers complete")
        expectation.expectedFulfillmentCount = 2
        var first: [Int] = []
        var second: [Int] = []

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            publisher.sink(
                receiveCompletion: { _ in expectation.fulfill() },
                receiveValue: { value in
                    first.append(value)
                }
            ).store(in: &self.cancellables)
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
            publisher.sink(
                receiveCompletion: { _ in expectation.fulfill() },
                receiveValue: { value in
                    second.append(value)
                }
            ).store(in: &self.cancellables)
        }

        wait(for: [expectation], timeout: 1)

        XCTAssertEqual(first, [0, 1, 2, 3, 4], "The first subscriber receives the full sequence", line: line)
        XCTAssertGreaterThan(first.count, second.count, "The second subscriber only recieves a subset of the full sequence", line: line)
        XCTAssert(first.ends(with: second), "The second subscriber receives the tail of the full sequence", line: line)
    }

    func testMultiSubscriptionWithMultiDelay() {
        let (stream, _) = createComparisonPublishers()
        multiSubscriptionWithMultiDelay(publisher: stream)
    }

    func testMultiSubscriptionWithMultiDelay_Reference() {
        let (_, timer) = createComparisonPublishers()
        multiSubscriptionWithMultiDelay(publisher: timer)
    }

}
