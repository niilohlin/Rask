import XCTest
import Rask

final class ParserTests: XCTestCase {
    func testParseChar() throws {
        let charParser = Rask.Parser<Character>.character(Character("a"))

        var inputString = "apa"

        let parsed = try charParser.parse(&inputString)
        XCTAssertEqual(parsed, Character("a"))
        XCTAssertEqual(inputString, "pa")
    }
}
