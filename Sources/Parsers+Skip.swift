import Foundation

extension Parsers {
    public struct Skip<Upstream: Parser, Skipping: Parser>: Parser {
        public let upstream: Upstream
        public let skipping: Skipping

        init(upstream: Upstream, skipping: Skipping) {
            self.upstream = upstream
            self.skipping = skipping
        }

        public func parse(_ input: String, _ index: inout String.Index) throws -> Upstream.Output {
            let value = try upstream.parse(input, &index)
            _ = try skipping.parse(input, &index)
            return value
        }
    }
}

extension Parser {
    public func skip<Skipping: Parser>(_ skipping: Skipping) -> Parsers.Skip<Self, Skipping> {
        Parsers.Skip(upstream: self, skipping: skipping)
    }
}
