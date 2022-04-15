import Foundation

extension Parsers {
    public struct Lexeme<Upstream: Parser>: Parser where Upstream.Input.Element == Character {
        public let upstream: Upstream

        init(upstream: Upstream) {
            self.upstream = upstream
        }

        public func parse(_ input: Upstream.Input, _ index: inout Upstream.Input.Index) throws -> Upstream.Output {
            let value = try upstream.parse(input, &index)

            while index < input.endIndex, input[index].unicodeScalars.allSatisfy(CharacterSet.whitespacesAndNewlines.contains) {
                index = input.index(after: index)
            }
            return value
        }
    }
}

extension Parser where Input.Element == Character {
    public func lexeme() -> Parsers.Lexeme<Self> {
        Parsers.Lexeme(upstream: self)
    }
}

extension Parsers.Lexeme {
    public func lexeme() -> Self {
        self
    }
}
