import Foundation

extension Parsers {
    public struct VoidParser<Upstream: Parser>: Parser {
        public let upstream: Upstream
        init(upstream: Upstream) {
            self.upstream = upstream
        }

        public func parse(_ input: String, _ index: inout String.Index) throws -> Void {
            _ = try upstream.parse(input, &index)
            return ()
        }
    }
}

extension Parser {
    public func toVoid() -> Parsers.VoidParser<Self> {
        Parsers.VoidParser(upstream: self)
    }
}
