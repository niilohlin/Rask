import Foundation

extension Parsers {
    public struct Separated<Upstream: Parser, Separator: Parser>: Parser where Upstream.Input == Separator.Input {
        public let upstream: Upstream
        public let separator: Separator

        public init(upstream: Upstream, separator: Separator) {
            self.upstream = upstream
            self.separator = separator
        }

        public func parse(_ input: Upstream.Input, _ index: inout Upstream.Input.Index) throws -> [Upstream.Output] {
            try upstream.separatedNonEmpty(by: separator).or(Parsers.always([])).parse(input, &index)
        }
    }
}

extension Parser {
    public func separated<Separator: Parser>(by separator: Separator) -> Parsers.Separated<Self, Separator> {
        Parsers.Separated(upstream: self, separator: separator)
    }
}

extension Parser where Input.Element == Character {
    public func separated(by separator: String) -> Parsers.Separated<Self, Parsers.StringParser<Input>> {
        Parsers.Separated(upstream: self, separator: Parsers.StringParser(string: separator))
    }
}
