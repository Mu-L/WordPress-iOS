import Foundation
import Combine
import XCTest

class AsyncPublisherTests: XCTestCase {

    func testCollectValues() async throws {
        let publisher = Array(1...10).publisher
        let values = await publisher.values.reduce(into: []) { $0.append($1) }
        XCTAssertEqual(values, Array(1...10))
    }

    func testCollectError() async throws {
        struct TestError: Error {}

        let publisher = Fail(outputType: Int.self, failure: TestError())
        do {
            let _: [Int] = try await publisher.values.reduce(into: []) { $0.append($1) }
            XCTFail("Unexpected success")
        } catch {
            XCTAssertTrue(error is TestError)
        }
    }

    func testEmitValuesAndError() async throws {
        struct TestError: Error {}

        let publisher = Record(output: [1, 2, 3], completion: .failure(TestError()))

        var values = [Int]()
        do {
            for try await value in publisher.values {
                values.append(value)
            }
            XCTFail("Unexpected success")
        } catch {
            XCTAssertTrue(error is TestError)
            XCTAssertEqual(values, [1, 2, 3])
        }
    }

    func testCancellation() async throws {
        let publisherCancelled = expectation(description: "Cancelled")
        let publisher = Just(42)
            .setFailureType(to: Error.self)
            .delay(for: .milliseconds(300), scheduler: DispatchQueue.main)
            .handleEvents(receiveCancel: publisherCancelled.fulfill)

        let collected = self.expectation(description: "No output because task is cancelled")
        let task = Task {
            let values = try await publisher.values.reduce(into: []) { $0.append($1) }
            XCTAssertEqual(values, [])
            collected.fulfill()
        }

        try await Task.sleep(for: .milliseconds(100))
        task.cancel()

        await fulfillment(of: [publisherCancelled, collected], timeout: 0.5)
    }

    func testCancelErrorPublisher() async throws {
        struct TestError: Error {}

        let publisherCancelled = expectation(description: "Cancelled")
        let publisher = Fail(outputType: Int.self, failure: TestError())
            .delay(for: .milliseconds(300), scheduler: DispatchQueue.main)
            .handleEvents(receiveCancel: publisherCancelled.fulfill)

        let collected = self.expectation(description: "No output because task is cancelled")
        let task = Task {
            let values = try await publisher.values.reduce(into: []) { $0.append($1) }
            XCTAssertEqual(values, [])
            collected.fulfill()
        }

        try await Task.sleep(for: .milliseconds(100))
        task.cancel()

        await fulfillment(of: [publisherCancelled, collected], timeout: 0.5)
    }

}
