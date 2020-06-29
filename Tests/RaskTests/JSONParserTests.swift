import Foundation
import XCTest
import Rask

extension Parser where T == [String: Any] {
    static func null() -> Parser<Any?> {
        return Parser<String>.string("null").lexeme().map { _ in nil }
    }

    static func jsonNumber() -> Parser<Double> {
        return Parser.one(of: "01234567890-.").manyNonEmpty().lexeme().flatMap { (chars) -> Parser<Double> in
            return Parser<Double> { _, _ in
                guard let double = Double(String(chars)) else {
                    throw NSError(domain: "not a double", code: 0, userInfo: [:])
                }
                return double
            }
        }.backtrack()
    }

    static func bool() -> Parser<Bool> {
        return Parser<String>.string("true").or(Parser<String>.string("false")).map { bool in
            bool == "true"
        }.lexeme().backtrack()
    }

    static func jsonString() -> Parser<String> {
        return Parser.one(of: "\"'").flatMap { openCharacter in
            Parser<String> { input, index in
                var result = ""
                while input[index] != openCharacter {
                    let char = input[index]
                    if char == Character("\\") {
                        index = input.index(index, offsetBy: 1)
                    }
                    result.append(input[index])
                    index = input.index(index, offsetBy: 1)
                }
                index = input.index(index, offsetBy: 1)
                return result
            }
        }.backtrack().lexeme()
    }

    static func jsonValue() -> Parser<Any> {
        return jsonString().map { $0 as Any }
            .or(jsonNumber().map { $0 as Any })
            .or(bool().map { $0 as Any })
            .or(jsonArray().map { $0 as Any })
            .or(object().map { $0 as Any })
    }

    static func jsonArray() -> Parser<[Any]> {
        Parser<Character>.character(Character("[")).lexeme().then {
            jsonValue().separated(by: comma).skip(Parser<Character>.character(Character("]"))).lexeme()
        }.backtrack()
    }

    static func keyValuePair() -> Parser<(String, Any)> {
        return jsonString().flatMap { key in
            Parser<Character>.character(Character(":")).lexeme().flatMap { _ in
                jsonValue().map { value in
                    (key, value)
                }
            }
        }
    }

    static let comma = Parser<Character>.character(Character(",")).lexeme().toVoid()

    static func object() -> Parser<[String: Any]> {
        Parser<Character>.character(Character("{")).lexeme().then {
            keyValuePair().separated(by: comma).skip(Parser<Character>.character(Character("}")).lexeme())
        }.map(Dictionary.init(uniqueKeysWithValues:)).backtrack()
    }
}

final class JSONParesrTests: XCTestCase {
    func testParseNumber() throws {
        let examples = [
            ("0", 0),
            ("0.0", 0.0),
            (".0", 0.0),
            ("-5", -5),
            ("-5.0", -5),
            ("5.", 5)
        ]
        try runExample(examples: examples, parser: Parser<[String: Any]>.jsonNumber())
    }

    func testString() throws {
        let examples = [
            ("\"\"", ""),
            ("\"test\"", "test"),
            ("\"\\\"test\"", "\"test"),
            ("'test'", "test")
        ]
        try runExample(examples: examples, parser: Parser<[String: Any]>.jsonString())
    }

    func testJsonObject() throws {
        let examples: [(String, [String: Double])] = [
            ("{}", [:]),
            ("{\"a\": 5}", ["a": 5.0]),
            ("{\"a\": 5, \"b\": 7}", ["a": 5.0, "b": 7])
        ]
        try runExample(examples: examples, parser: Parser<[String: Any]>.object().map { $0 as! [String: Double] })
    }

    func testComplexObject() throws {
        let input = "{\"a\": {}, \"b\": [{\"c\": []}]}"
        var index = input.startIndex
        let expected: [String: Any] = ["a": [:], "b": ["c": []]]
        let parser = Parser<[String: Any]>.object()

        XCTAssertNoThrow(try parser.parse(input, &index))

        XCTAssertEqual(index, input.endIndex, "input was not consumed. rest: \(input)")
    }
}
