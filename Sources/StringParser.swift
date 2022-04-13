import Foundation

extension Parsers {
    public struct StringParser: Parser {
        public typealias Output = String
        let string: String
        public init(string: String) {
            self.string = string
        }

        public func parse(_ input: String, _ index: inout String.Index) throws -> String {
            guard input.endIndex > index else {
                throw AnyUnexpectedToken(expected: "not eof", actual: "")
            }

            guard let end = input.index(index, offsetBy: string.count, limitedBy: input.endIndex) else {
                throw AnyUnexpectedToken(expected: string, actual: input)
            }

            guard String(input[Range(uncheckedBounds: (lower: index, upper: end))]) == string else {
                throw AnyUnexpectedToken(expected: string, actual: input)
            }
            index = end
            return string
        }
    }
}

public extension Parsers {
    static func string(_ string: String) -> StringParser {
        StringParser(string: string)
    }
}

extension Parsers.StringParser: ExpressibleByStringLiteral {
    public init(stringLiteral: StringLiteralType) {
        self.init(string: stringLiteral)
    }
}
