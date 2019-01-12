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

    func testParseArithmetic() throws {
        indirect enum Expr {
            case number(Int)
            case add(Expr, Expr)
            case mul(Expr, Expr)
        }

        let expression = "(1+2)*2+1"
        let intParser = Parser<Expr>.or(
                Parser<Character>.character(Character("1")),
                Parser<Character>.character(Character("2"))
        ).map { char in
            Expr.number(Int(String(char))!)
        }


//        let parenParser = Parser<Expr> { input in
//
//        }
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
