import Foundation
import XCTest
import Rask

extension AnyParser where T == [String: Any] {
    static func null() -> AnyParser<Any?> {
        Parsers.string("null").lexeme().map { _ in nil }.eraseToAnyParser()
    }

    static func jsonNumber() -> AnyParser<Double> {
        return AnyParser.one(of: "01234567890-.").manyNonEmpty().lexeme().flatMap { (chars) -> AnyParser<Double> in
            return AnyParser<Double> { _, _ in
                guard let double = Double(String(chars)) else {
                    throw NSError(domain: "not a double", code: 0, userInfo: [:])
                }
                return double
            }
        }.backtrack()
    }

    static func bool() -> AnyParser<Bool> {
        return Parsers.string("true").or(Parsers.string("false").eraseToAnyParser()).map { bool in
            bool == "true"
        }.lexeme().backtrack()
    }

    static func jsonString() -> AnyParser<String> {
        return AnyParser.one(of: "\"'").flatMap { openCharacter in
            AnyParser<String> { input, index in
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

    static func jsonValue() -> AnyParser<Any> {
        return jsonString().map { $0 as Any }
            .or(jsonNumber().map { $0 as Any })
            .or(bool().map { $0 as Any })
            .or(jsonArray().map { $0 as Any })
            .or(object().map { $0 as Any })
    }

    static func jsonArray() -> AnyParser<[Any]> {
        AnyParser<Character>.character(Character("[")).lexeme().then {
            jsonValue().separated(by: comma).skip(AnyParser<Character>.character(Character("]"))).lexeme()
        }.backtrack()
    }

    static func keyValuePair() -> AnyParser<(String, Any)> {
        jsonString().flatMap { key in
            AnyParser<Character>.character(Character(":")).lexeme().flatMap { _ in
                jsonValue().map { value in
                    (key, value)
                }.eraseToAnyParser()
            }
        }.eraseToAnyParser()
    }

    static let comma = AnyParser<Character>.character(Character(",")).lexeme().toVoid().eraseToAnyParser()

    static func object() -> AnyParser<[String: Any]> {
        AnyParser<Character>.character(Character("{")).lexeme().then {
            keyValuePair().separated(by: comma).skip(AnyParser<Character>.character(Character("}")).lexeme())
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
        try runExample(examples: examples, parser: AnyParser<[String: Any]>.jsonNumber())
    }

    func testString() throws {
        let examples = [
            ("\"\"", ""),
            ("\"test\"", "test"),
            ("\"\\\"test\"", "\"test"),
            ("'test'", "test")
        ]
        try runExample(examples: examples, parser: AnyParser<[String: Any]>.jsonString())
    }

    func testJsonObject() throws {
        let examples: [(String, [String: Double])] = [
            ("{}", [:]),
            ("{\"a\": 5}", ["a": 5.0]),
            ("{\"a\": 5, \"b\": 7}", ["a": 5.0, "b": 7])
        ]
        try runExample(examples: examples, parser: AnyParser<[String: Any]>.object().map { $0 as! [String: Double] }.eraseToAnyParser())
    }

    func testComplexObject() throws {
        let input = "{\"a\": {}, \"b\": [{\"c\": []}]}"
        var index = input.startIndex
        let expected: [String: Any] = ["a": [:], "b": ["c": []]]
        let parser = AnyParser<[String: Any]>.object()

        XCTAssertNoThrow(try parser.parse(input, &index))

        XCTAssertEqual(index, input.endIndex, "input was not consumed. rest: \(input)")
    }
}
