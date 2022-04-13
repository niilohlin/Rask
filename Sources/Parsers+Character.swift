import Foundation

extension Parsers {
    public struct WrongCharacterError: UnexpectedToken {
        let expected: Character
        var actual: Character
    }
    public struct CharacterParser: Parser {
        public let char: Character

        public init(_ char: Character) {
            self.char = char
        }

        public func parse(_ input: String, _ index: inout String.Index) throws -> Character {
            guard input.endIndex > index else {
                throw AnyUnexpectedToken(expected: "not eof", actual: "")
            }

            guard input[index] == char else {
                throw WrongCharacterError(expected: char, actual: input[index])
            }
            index = input.index(after: index)
            return char
        }
    }
}

extension Parsers {
    public static func character(_ char: Character) -> Parsers.CharacterParser {
        Parsers.CharacterParser(char)
    }

    public static func character(_ string: String) -> Parsers.CharacterParser {
        assert(string.count == 1)
        return Parsers.CharacterParser(string[string.startIndex])
    }
}

extension Parsers.CharacterParser {
    public func or(other: Parsers.CharacterParser) -> Parsers.OneOf {
        let otherString = String(other.char)
        let upstreamString = String(char)
        return Parsers.OneOf(string: upstreamString + otherString)
    }
}
