import Foundation
import XCTest
import AsyncAlgorithms

class StandardStreamTests: XCTestCase {

    func testColdSequence() async throws {
        let sequence = Array(1...50).async.prefix(10)
        let consumer1: [Int] = await sequence.reduce(into: []) { $0.append($1) }
        let consumer2: [Int] = await sequence.reduce(into: []) { $0.append($1) }
        XCTAssertEqual(consumer1, Array(1...10))
        XCTAssertEqual(consumer2, Array(1...10))
    }

}
