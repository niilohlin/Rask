import Foundation

extension Parsers {
    public struct Optional<Upstream: Parser>: Parser {
        public let upstream: Upstream
        init(upstream: Upstream) {
            self.upstream = upstream
        }

        public func parse(_ input: Upstream.Input, _ index: inout Upstream.Input.Index) throws -> Upstream.Output? {
            try? upstream.parse(input, &index)
        }
    }
}

extension Parser {
    public func optional() -> Parsers.Optional<Self> {
        Parsers.Optional(upstream: self)
    }
}
