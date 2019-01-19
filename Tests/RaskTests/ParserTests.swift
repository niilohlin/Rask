import XCTest
import Rask

final class ParserTests: XCTestCase {
    func testParseChar() throws {
        let charParser = Parser<Character>.character(Character("a"))

        var inputString = "apa"

        let parsed = try charParser.parse(&inputString)
        XCTAssertEqual(parsed, Character("a"))
        XCTAssertEqual(inputString, "pa")
    }

    func testMap() throws {
        let charParser = Parser<Character>.character(Character("a"))
        let singleStringParser = charParser.map(String.init)

        var inputString = "apa"

        let parsed = try singleStringParser.parse(&inputString)
        XCTAssertEqual(parsed, "a")
        XCTAssertEqual(inputString, "pa")
    }

    func testFlatMap() throws {
        let charParser = Parser<Character>.character(Character("a"))
        let abParser = charParser.flatMap { character in
            Parser<Character>.character(character.nextInAlphabet())
        }

        var inputString = "aba"

        let parsed = try abParser.parse(&inputString)
        XCTAssertEqual(parsed, Character("b"))
        XCTAssertEqual(inputString, "a")
    }

    func testFailingFlatMap() throws {
        let charParser = Parser<Character>.character(Character("a"))
        let abParser = charParser.flatMap { character in
            Parser<Character>.character(character.nextInAlphabet())
        }

        var inputString = "apa"

        _ = try? abParser.parse(&inputString)

        XCTAssertEqual(inputString, "apa")
    }

    func testSkip() throws {
        let charParser = Parser<Character>.character(Character("a")).skip(Parser<Character>.character(Character("p")))

        var inputString = "apa"

        let parsed = try charParser.parse(&inputString)
        XCTAssertEqual(parsed, Character("a"))
        XCTAssertEqual(inputString, "a")
    }

    func testString() throws {
        XCTAssertEqual(try Parser<String>.string("test").parse(input: "test"), "test")
    }

    func testManyNonEmpty() throws {
        let characters = Parser<Character>.one(of: "abc").manyNonEmpty().map { String($0) }
        var input = "aaabbcd"
        let result = try characters.parse(&input)
        XCTAssertEqual(result, "aaabbc")
        XCTAssertEqual(input, "d")
    }

    func testManyNonEmpty_failing() throws {
        let characters = Parser<Character>.one(of: "abc").manyNonEmpty().map { String($0) }
        var input = "derp"
        XCTAssertThrowsError(try characters.parse(&input))
        XCTAssertEqual(input, "derp")
    }
}

extension Character {
    func nextInAlphabet() -> Character {
        let alphabet = "abcdefghijklmnopqrstuvwxyz"
        let indexOfSelf = alphabet.firstIndex(of: self)!
        let indexOfNext = alphabet.index(indexOfSelf, offsetBy: 1)
        return alphabet[indexOfNext]

    }
}
