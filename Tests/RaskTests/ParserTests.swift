import XCTest
import Rask

final class ParserTests: XCTestCase {
    func testParseChar() throws {
        let charParser = Parser<Character>.character(Character("a"))

        let inputString = "apa"
        var index = inputString.startIndex

        let parsed = try charParser.parse(inputString, &index)
        XCTAssertEqual(parsed, Character("a"))
        XCTAssertEqual(index, inputString.index(inputString.startIndex, offsetBy: 1))
    }

    func testFailingParser() {
        let charParser = Parser<Character>.character(Character("a"))

        let inputString = "pa"
        var index = inputString.startIndex

        XCTAssertThrowsError(try charParser.parse(inputString, &index))
        XCTAssertEqual(index, inputString.startIndex)
    }

    func testMap() throws {
        let charParser = Parser<Character>.character(Character("a"))
        let singleStringParser = charParser.map(String.init)

        let inputString = "apa"
        var index = inputString.startIndex

        let parsed = try singleStringParser.parse(inputString, &index)
        XCTAssertEqual(parsed, "a")
        XCTAssertEqual(index, inputString.index(inputString.startIndex, offsetBy: 1))
    }

    func testFlatMap() throws {
        let charParser = Parser<Character>.character(Character("a"))
        let abParser = charParser.flatMap { character in
            Parser<Character>.character(character.nextInAlphabet())
        }

        let inputString = "aba"
        var index = inputString.startIndex

        let parsed = try abParser.parse(inputString, &index)
        XCTAssertEqual(parsed, Character("b"))
        XCTAssertEqual(index, inputString.index(inputString.startIndex, offsetBy: 2))
    }

    func testFailingFlatMap() throws {
        let charParser = Parser<Character>.character(Character("a"))
        let abParser = charParser.flatMap { character in
            Parser<Character>.character(character.nextInAlphabet())
        }

        let inputString = "apa"
        var index = inputString.startIndex

        _ = try? abParser.parse(inputString, &index)

        XCTAssertEqual(inputString, "apa")
        XCTAssertEqual(index, inputString.startIndex)
    }

    func testSkip() throws {
        let charParser = Parser<Character>.character(Character("a")).skip(Parser<Character>.character(Character("p")))

        let inputString = "apa"
        var index = inputString.startIndex

        let parsed = try charParser.parse(inputString, &index)
        XCTAssertEqual(parsed, Character("a"))
        XCTAssertEqual(index, inputString.index(inputString.startIndex, offsetBy: 2))
    }

    func testString() throws {
        XCTAssertEqual(try Parser<String>.string("test").parse(input: "test"), "test")
    }

    func testManyNonEmpty() throws {
        let characters = Parser<Character>.one(of: "abc").manyNonEmpty().map { String($0) }
        let input = "aaabbcd"
        var index = input.startIndex
        let result = try characters.parse(input, &index)
        XCTAssertEqual(result, "aaabbc")
        XCTAssertEqual(index, input.index(input.startIndex, offsetBy: 6))
    }

    func testManyNonEmpty_failing() throws {
        let characters = Parser<Character>.one(of: "abc").manyNonEmpty().map { String($0) }
        let input = "derp"
        var index = input.startIndex
        XCTAssertThrowsError(try characters.parse(input, &index))
        XCTAssertEqual(index, input.startIndex)
    }

    func testSeparatedBy() throws {
        let characters = Parser<Character>.character(Character("a")).separated(by: " ")
        let input = "a a a a"
        var index = input.startIndex
        let result = try characters.parse(input, &index)
        XCTAssertEqual(result, [Character("a"), Character("a"), Character("a"), Character("a")])
        XCTAssertEqual(index, input.endIndex)
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
