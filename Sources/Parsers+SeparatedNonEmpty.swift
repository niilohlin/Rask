import Foundation

extension Parsers {
    public struct SeparatedNonEmpty<Upstream: Parser, Separator: Parser>: Parser where Upstream.Input == Separator.Input {
        public let upstream: Upstream
        public let separator: Separator

        public init(upstream: Upstream, separator: Separator) {
            self.upstream = upstream
            self.separator = separator
        }

        public func parse(_ input: Upstream.Input, _ index: inout Upstream.Input.Index) throws -> [Upstream.Output] {
            try upstream.flatMap { firstMatch in
                (separator.then { upstream }).many().map { rest in
                    [firstMatch] + rest
                }
            }.parse(input, &index)
        }
    }
}

extension Parser {
    public func separatedNonEmpty<Separator: Parser>(by separator: Separator) -> Parsers.SeparatedNonEmpty<Self, Separator> {
        Parsers.SeparatedNonEmpty(upstream: self, separator: separator)
    }
}
