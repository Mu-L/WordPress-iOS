import Foundation
import Combine
import XCTest

@testable import AsyncCombine

class FetchOnce: XCTestCase {

    var tracks: Tracks!

    override func setUp() {
        super.setUp()
        tracks = Tracks()
    }

    func testMultipleFetchesBeforeTaskCompletes() async throws {
        let expectation = self.expectation(description: "All fetches are completed")
        expectation.expectedFulfillmentCount = 2

        let imageDownloader = ImageDownloader(tracks: tracks)

        for _ in 1...expectation.expectedFulfillmentCount {
            try await Task.sleep(for: .milliseconds(100))
            Task.detached {
                do {
                    let image = try await imageDownloader.fetch()
                    XCTAssertEqual(image, "IMAGE")
                } catch {
                    XCTFail("Unexpected error: \(error)")
                }

                expectation.fulfill()
            }
        }

        await fulfillment(of: [expectation], timeout: 1)

        let events = await tracks.events
        XCTAssertEqual(events.count(where: { $0 == .HTTPGetCalled }), 1)
    }

    func testMultipleFetchesBeforeSecondTaskCompletes() async throws {
        let expectation = self.expectation(description: "All fetches are completed")
        expectation.expectedFulfillmentCount = 6

        let imageDownloader = ImageDownloader(tracks: tracks)

        for _ in 1...expectation.expectedFulfillmentCount {
            try await Task.sleep(for: .milliseconds(80))
            Task.detached {
                do {
                    let image = try await imageDownloader.fetch()
                    XCTAssertEqual(image, "IMAGE")
                } catch {
                    XCTFail("Unexpected error: \(error)")
                }

                expectation.fulfill()
            }
        }

        await fulfillment(of: [expectation], timeout: 1)

        let events = await tracks.events
        XCTAssertEqual(events.count(where: { $0 == .HTTPGetCalled }), 2)
    }

    func testCancellation_Reference() async throws {
        let cancelled = expectation(description: "Cancelled")
        let timer = Just(42)
            .delay(for: .milliseconds(300), scheduler: DispatchQueue.main)
            .handleEvents(receiveCancel: cancelled.fulfill)

        let expectation = self.expectation(description: "Cancelled")
        let task = Task {
            let result = await timer.values.first { _ in true }
            if result == nil {
                expectation.fulfill()
            }
        }

        try await Task.sleep(for: .milliseconds(100))
        task.cancel()

        await fulfillment(of: [cancelled, expectation], timeout: 1)
    }

    func testCancellation() async throws {
        let expectation = expectation(description: "Cancelled")
        let imageDownloader = ImageDownloader(tracks: tracks)
        let task = Task {
            do {
                let _ = try await imageDownloader.fetch()
                XCTFail("Unexpected success")
            } catch {
                expectation.fulfill()
            }
        }

        try await Task.sleep(for: .milliseconds(100))
        task.cancel()

        await fulfillment(of: [expectation], timeout: 1)

        let events = await tracks.events
        XCTAssertEqual(events.count(where: { $0 == .HTTPGetCalled }), 1)
        XCTAssertFalse(events.contains(.HTTPGetCompleted))
    }

    func testCancelMultipleFetches() async throws {
        let expectation = expectation(description: "Cancelled")
        expectation.expectedFulfillmentCount = 2

        let imageDownloader = ImageDownloader(tracks: tracks)
        var tasks: [Task<Void, Never>] = []
        for _ in 1...2 {
            let task = Task {
                do {
                    let _ = try await imageDownloader.fetch()
                    XCTFail("Unexpected success")
                } catch {
                    expectation.fulfill()
                }
            }
            tasks.append(task)
            try await Task.sleep(for: .milliseconds(100))
        }

        for task in tasks {
            task.cancel()
        }

        await fulfillment(of: [expectation], timeout: 1)

        let events = await tracks.events
        XCTAssertEqual(events.count(where: { $0 == .HTTPGetCalled }), 1)
        XCTAssertFalse(events.contains(.HTTPGetCompleted))
    }

    func testCancelSomeButNotAllFetches() async throws {
        let success = expectation(description: "Successful result")
        success.expectedFulfillmentCount = 3

        let imageDownloader = ImageDownloader(tracks: tracks)
        for _ in 1...3 {
            Task.detached {
                do {
                    let _ = try await imageDownloader.fetch()
                    success.fulfill()
                } catch {
                    XCTFail("Unexpected error")
                }
            }
            try await Task.sleep(for: .milliseconds(10))
        }

        let cancelled = expectation(description: "Cancelled")
        cancelled.expectedFulfillmentCount = 3
        var tasksToCancel: [Task<Void, Never>] = []
        for _ in 1...3 {
            let task = Task.detached {
                do {
                    let _ = try await imageDownloader.fetch()
                    XCTFail("Unexpected success")
                } catch {
                    cancelled.fulfill()
                }
            }
            tasksToCancel.append(task)
            try await Task.sleep(for: .milliseconds(10))
        }

        for task in tasksToCancel {
            task.cancel()
        }

        await fulfillment(of: [success, cancelled], timeout: 1)
    }

    func testTaskIsCanceled() async throws {
        let taskCancelled = expectation(description: "Task cancelled")
        let publisher = Task {
                do {
                    try await Task.sleep(for: .seconds(1))
                } catch is CancellationError {
                    taskCancelled.fulfill()
                } catch {
                    XCTFail("Unexpected error: \(error)")
                }
            }
            .publisher

        let tasks = [1...3].map { _ in
            Task.detached {
                let _ = try await publisher.values.reduce(into: []) { $0.append($1) }
            }
        }
        try await Task.sleep(for: .milliseconds(10))
        for task in tasks {
            task.cancel()
        }

        await fulfillment(of: [taskCancelled], timeout: 0.3)
    }

}

actor ImageDownloader {
    let tracks: Tracks
    let http: HTTP
    var publisher: AnyPublisher<String, Error>?
    var task: Task<String, Error>?

    init(tracks: Tracks) {
        self.tracks = tracks
        self.http = HTTP(tracks: tracks)
    }

    func fetch() async throws -> String {
        if publisher == nil {
            publisher = Task { try await self.http.get() }
                .stream
                .sharedPublisher
                .eraseToAnyPublisher()

            Task.detached { [tracks] in
                await tracks.log(.fetchPublisherCreated)
            }
        }
        Task.detached { [tracks] in
            await tracks.log(.fetchWaitForResult)
        }

        defer {
            publisher = nil
            Task.detached { [tracks] in
                await tracks.log(.fetchPublisherDestoryed)
            }
        }

        if let output = try await publisher!.values.first(where: { _ in true }) {
            return output
        }

        throw CancellationError()
    }
}

class HTTP {
    let tracks: Tracks

    init(tracks: Tracks) {
        self.tracks = tracks
    }

    func get() async throws -> String {
        await tracks.log(.HTTPGetCalled)
        try await Task.sleep(for: .milliseconds(300))
        await tracks.log(.HTTPGetCompleted)
        return "IMAGE"
    }
}

actor Tracks {
    enum Event: Equatable {
        case fetchPublisherCreated
        case fetchWaitForResult
        case fetchPublisherDestoryed
        case HTTPGetCalled
        case HTTPGetCompleted
    }

    var raw: [(Event, Date)] = []

    var events: [Event] {
        raw.map { event, _ in event }
    }

    func log(_ event: Event) {
        raw.append((event, Date()))
    }

    func print() {
        guard !events.isEmpty else { return }

        let startTime = raw.first!.1

        for (event, time) in raw {
            let duration = time.timeIntervalSince(startTime)
            let formattedDuration = String(format: "%.3f", duration)
            Swift.print("[\(formattedDuration)] \(event)")
        }
    }
}
