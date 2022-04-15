import Foundation

extension Parsers {
    public struct Skip<Upstream: Parser, Skipping: Parser>: Parser where Upstream.Input == Skipping.Input {
        public let upstream: Upstream
        public let skipping: Skipping

        init(upstream: Upstream, skipping: Skipping) {
            self.upstream = upstream
            self.skipping = skipping
        }

        public func parse(_ input: Upstream.Input, _ index: inout Upstream.Input.Index) throws -> Upstream.Output {
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
