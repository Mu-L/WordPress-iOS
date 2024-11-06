import XCTest
import WordPressShared

final class StringRankedSearchTests: XCTestCase {
    func testScoreInRange() {
        // High confidence
        XCTAssertInRange(0.8...1.0, score("Appleseed", "Appleseed"))
        XCTAssertInRange(0.8...1.0, score("John Appleseed", "Appleseed"))
        XCTAssertInRange(0.8...1.0, score("John Appleseed", "John"))
        XCTAssertInRange(0.8...1.0, score("John Appleseed", "App"))
        XCTAssertInRange(0.8...1.0, score("John O'Appleseed", "App"))
        XCTAssertInRange(0.8...1.0, score("john-appleseed", "j-a"))
        XCTAssertInRange(0.8...1.0, score("#john-appleseed", "john"))
        XCTAssertInRange(0.8...1.0, score("John Appleseed", "Apseed"))

        // Medium confidence
        XCTAssertInRange(0.5...0.8, score("John Appleseed", "A"))
        XCTAssertInRange(0.5...0.8, score("John Appleseed", "Ap"))
        XCTAssertInRange(0.5...0.8, score("John Appleseed", "ohn"))
        XCTAssertInRange(0.5...0.8, score("#john-appleseed", "j-a"))
        XCTAssertInRange(0.5...0.8, score("John Appleseed", "applex"))

        // Low confidence
        XCTAssertInRange(0.2...0.5, score("John Appleseed", "Ae"))
        XCTAssertInRange(0.2...0.5, score("John Appleseed", "Jn"))

        // Very low confidence
        XCTAssertInRange(0.0...0.2, score("John Appleseed", "o"))
        XCTAssertInRange(0.0...0.2, score("John Appleseed", "X"))
        XCTAssertInRange(0.0...0.2, score("John Appleseed", "x"))
        XCTAssertInRange(0.0...0.2, score("John Appleseed", "applexx"))
    }

    func testBonuses() {
        // Bonus for the number of the matching words in the input.
        XCTAssertLessThan(score("John Appleseed", "App"), score("Appleseed", "App"))

        // Bonus for distance between matches
        XCTAssertLessThan(score("John Xxxx Appleseed", "John Appleseed"), score("John Appleseed Xxxx", "John Appleseed"))

        // Bonus for distance between matches
        XCTAssertLessThan(score("John Xxxx Appleseed", "John Appleseed"), score("John Appleseed Xxxx", "John Appleseed"))

        // Bonus for distance between matches
        XCTAssertLessThan(score("John Xxxx Appleseed", "John Appleseed"), score("Xxxx John Appleseed", "John Appleseed"))

        // Bonus for more characters in a row
        XCTAssertLessThan(score("Apxplesee", "App"), score("Appleseed", "App"))

        // Bonus for more characters in a row is higher than the penalty for a number of matches
        XCTAssertLessThan(score("Apxplesee", "App"), score("John Appleseed", "App"))

        // Bonus for more characters in a row is higher than the penalty for mismatches case.
        XCTAssertLessThan(score("Apxplesee", "App"), score("appleseed", "App"))

        // The diacritics are considered a match
        XCTAssertLessThan(score("Kxhu", "Kahu"), score("Kāhu", "Kahu"))

        // Bonus for exact match diacritics are present
        XCTAssertLessThan(score("Kāhu", "Kahu"), score("Kahu", "Kahu"))

        // Bonus for exact match diacritics are present
        XCTAssertLessThan(score("Kāhu", "Kahu"), score("Kāhu", "Kāhu"))

        // Bonus for number length match
        XCTAssertLessThan(score("john-appleseed-xxxx", "project"), score("john-appleseed", "project"))
    }

    func testSearchBeginingOrEnd() {
        XCTAssertEqual(score("AB00", "AB"), score("ABXX", "AB"), accuracy: 0.1)
        XCTAssertEqual(score("4200", "42"), score("42XX", "42"), accuracy: 0.1)

        XCTAssertEqual(score("00AB", "AB"), score("XXAB", "AB"), accuracy: 0.1)
        XCTAssertEqual(score("0042", "42"), score("XX42", "42"), accuracy: 0.1)

        XCTAssertEqual(score("AB_00", "AB"), score("AB_XX", "AB"), accuracy: 0.1)
        XCTAssertEqual(score("42_00", "42"), score("42_XX", "42"), accuracy: 0.1)

        XCTAssertEqual(score("00_AB", "AB"), score("XX_AB", "AB"), accuracy: 0.1)
        XCTAssertEqual(score("00_42", "42"), score("XX_42", "42"), accuracy: 0.1)

        XCTAssertEqual(score("AB/00", "AB"), score("AB/XX", "AB"), accuracy: 0.1)
        XCTAssertEqual(score("42/00", "42"), score("42/XX", "42"), accuracy: 0.1)

        XCTAssertEqual(score("00/AB", "AB"), score("XX/AB", "AB"), accuracy: 0.1)
        XCTAssertEqual(score("00/42", "42"), score("XX/42", "42"), accuracy: 0.1)
    }

    func testCompareSearchNumbersAndLetters() {
        XCTAssertEqual(score("42XX", "42"), score("ABXX", "AB"), accuracy: 0.1)
        XCTAssertEqual(score("0042", "42"), score("XXAB", "AB"), accuracy: 0.1)
        XCTAssertEqual(score("42_00", "42"), score("AB_XX", "AB"), accuracy: 0.1)
        XCTAssertEqual(score("00_42", "42"), score("XX_AB", "AB"), accuracy: 0.1)
        XCTAssertEqual(score("42/00", "42"), score("AB/XX", "AB"), accuracy: 0.1)
        XCTAssertEqual(score("00/42", "42"), score("XX/AB", "AB"), accuracy: 0.1)
    }

    func xtestPerformance() throws {
        measure {
            for _ in 0..<10000 {
                _ = score("John Appleseed", "John")
            }
        }
    }
}

private func score(_ lhs: String, _ rhs: String) -> Double {
    StringRankedSearch(searchTerm: rhs).score(for: lhs)
}

private func XCTAssertInRange<T: Comparable>(_ range: some RangeExpression<T>, _ value: T, file: StaticString = #filePath, line: UInt = #line) {
    XCTAssert(range.contains(value), "(\"\(value)\") is not in (\"\(range)\")", file: file, line: line)
}
