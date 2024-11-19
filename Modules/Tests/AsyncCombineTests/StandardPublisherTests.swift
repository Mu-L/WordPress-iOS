import XCTest
import Combine

@testable import AsyncCombine

class StandardPublisherTests: XCTestCase {
    var cancellables: Set<AnyCancellable> = []

    override func tearDown() {
        super.tearDown()
        cancellables.removeAll()
    }

    func testEmitsValues() {
        let expectation = XCTestExpectation(description: "Publisher emits values")
        var receivedValues: [Int] = []

        let publisher = JustAsyncSequence(42).publisher
        publisher.sink(
            receiveCompletion: { _ in },
            receiveValue: { value in
                receivedValues.append(value)
                expectation.fulfill()
            }
        ).store(in: &cancellables)

        wait(for: [expectation], timeout: 0.3)
        XCTAssertEqual(receivedValues, [42])
    }

    func testCompletes() {
        let expectation = XCTestExpectation(description: "Publisher completes")

        let publisher = JustAsyncSequence(42).publisher
        publisher.sink(
            receiveCompletion: { completion in
                if case .finished = completion {
                    expectation.fulfill()
                }
            },
            receiveValue: { _ in }
        ).store(in: &cancellables)

        wait(for: [expectation], timeout: 0.3)
    }

    func testPropagatesError() {
        let expectation = XCTestExpectation(description: "Publisher propagates error")

        struct TestError: Error {}
        let publisher = JustThrowingAsyncSequence<Int>(TestError()).publisher
        publisher.sink(
            receiveCompletion: { completion in
                if case .failure(let error) = completion {
                    XCTAssertTrue(error is TestError)
                    expectation.fulfill()
                }
            },
            receiveValue: { _ in XCTFail("Should not emit values") }
        ).store(in: &cancellables)

        wait(for: [expectation], timeout: 0.3)
    }

    func testHandlesCancellation() {
        let expectation = XCTestExpectation(description: "Publisher is cancelled")
        expectation.isInverted = true

        let cancelled = XCTestExpectation(description: "Task is cancelled")
        cancelled.isInverted = true

        let publisher = JustThrowingAsyncSequence {
                try await Task.sleep(for: .microseconds(300))
                cancelled.fulfill()
                return 42
            }
            .publisher
        let cancellable = publisher.sink(
            receiveCompletion: { _ in XCTFail("Should not complete") },
            receiveValue: { _ in XCTFail("Should not emit values") }
        )
        cancellable.cancel()

        wait(for: [expectation], timeout: 0.5)
    }

    func testFirstOperator() {
        let expectation = XCTestExpectation(description: "Publisher emits first value and completes")
        var receivedValues: [Int] = []

        let publisher = Counter(start: 0, end: 9, interval: .milliseconds(100))
            .publisher
        let firstPublisher = publisher.first()

        firstPublisher.sink(
            receiveCompletion: { completion in
                if case .finished = completion {
                    expectation.fulfill()
                }
            },
            receiveValue: { value in
                receivedValues.append(value)
            }
        ).store(in: &cancellables)

        wait(for: [expectation], timeout: 1.0)
        XCTAssertEqual(receivedValues, [0])
    }

    func testPrefixOperator() {
        let expectation = XCTestExpectation(description: "Publisher emits first N values and completes")
        var receivedValues: [Int] = []

        let publisher = Counter(start: 0, end: 9, interval: .milliseconds(100))
            .publisher
        let prefixedPublisher = publisher.prefix(3)

        prefixedPublisher.sink(
            receiveCompletion: { completion in
                if case .finished = completion {
                    expectation.fulfill()
                }
            },
            receiveValue: { value in
                receivedValues.append(value)
            }
        ).store(in: &cancellables)

        wait(for: [expectation], timeout: 1.0)
        XCTAssertEqual(receivedValues, [0, 1, 2])
    }

}
