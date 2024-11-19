import Foundation
import XCTest

struct Counter: AsyncSequence {
    typealias Element = Int
    let start: Int
    let end: Int
    let interval: Duration

    struct AsyncIterator: AsyncIteratorProtocol {
        let start: Int
        let end: Int
        let interval: Duration
        var current: Int

        init(start: Int, end: Int, interval: Duration) {
            self.start = start
            self.end = end
            self.interval = interval
            self.current = start
        }

        mutating func next() async throws -> Int? {
            try await Task.sleep(for: interval)

            guard current <= end else {
                return nil
            }

            let result = current
            current += 1
            return result
        }
    }

    func makeAsyncIterator() -> AsyncIterator {
        return AsyncIterator(start: start, end: end, interval: interval)
    }
}

extension Sequence where Element: Equatable {
    func ends<S: Sequence>(with other: S) -> Bool where Element == S.Element {
        reversed().starts(with: other.reversed())
    }
}

class SupportTests: XCTestCase {

    func testEndsWith() {
        XCTAssertFalse([1, 2, 3].ends(with: [1]))
        XCTAssertFalse([1, 2, 3].ends(with: [1, 3]))

        XCTAssertTrue([1, 2, 3].ends(with: [3]))
        XCTAssertTrue([1, 2, 3].ends(with: [2, 3]))
        XCTAssertTrue([1, 2, 3].ends(with: [1, 2, 3]))
    }

}
