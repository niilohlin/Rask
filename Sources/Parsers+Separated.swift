import Foundation

extension Parsers {
    public struct Separated<Upstream: Parser, Separator: Parser>: Parser {
        public let upstream: Upstream
        public let separator: Separator

        public init(upstream: Upstream, separator: Separator) {
            self.upstream = upstream
            self.separator = separator
        }

        public func parse(_ input: String, _ index: inout String.Index) throws -> [Upstream.Output] {
            try upstream.separatedNonEmpty(by: separator).or(Parsers.always([])).parse(input, &index)
        }
    }
}

extension Parser {
    public func separated<Separator: Parser>(by separator: Separator) -> Parsers.Separated<Self, Separator> {
        Parsers.Separated(upstream: self, separator: separator)
    }

    public func separated(by separator: String) -> Parsers.Separated<Self, Parsers.StringParser> {
        Parsers.Separated(upstream: self, separator: Parsers.StringParser(string: separator))
    }
}
