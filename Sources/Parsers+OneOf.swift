import Foundation

extension Parsers {
    public struct OneOf: Parser {
        public let set: Set<Character>

        public init(string: String) {
            self.set = Set(string)
        }

        public func parse(_ input: String, _ index: inout String.Index) throws -> Character {
            guard input.endIndex > index else {
                throw AnyUnexpectedToken(expected: "not eof", actual: "")
            }

            let firstElement = input[index]
            guard set.contains(firstElement) else {
                throw NotOneOfError(expected: set, actual: firstElement)
            }
            index = input.index(after: index)
            return firstElement
        }
    }
}

extension Parsers {
    public static func one(of string: String) -> Parsers.OneOf {
        Parsers.OneOf(string: string)
    }

    public static func digit() -> Parsers.OneOf {
        Parsers.one(of: "0123456789")
    }
}

extension Parsers.OneOf {
    public func or(other: Parsers.OneOf) -> Parsers.OneOf {
        let otherString = other.set.map { String($0) }.joined(separator: "")
        let upstreamString = `set`.map { String($0) }.joined(separator: "")
        return Parsers.OneOf(string: upstreamString + otherString)
    }
}
