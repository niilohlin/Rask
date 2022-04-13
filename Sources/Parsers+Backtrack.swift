import Foundation

extension Parsers {
    public struct Backtrack<Upstream: Parser>: Parser {
        public let upstream: Upstream

        init(upstream: Upstream) {
            self.upstream = upstream
        }

        public func parse(_ input: String, _ index: inout String.Index) throws -> Upstream.Output {
            var backup = index
            let result = try upstream.parse(input, &backup)
            index = backup
            return result
        }
    }
}

extension Parser {
    public func backtrack() -> Parsers.Backtrack<Self> {
        Parsers.Backtrack(upstream: self)
    }
}

extension Parsers.Backtrack {
    public func backtrack() -> Parsers.Backtrack<Upstream> {
        self
    }
}
