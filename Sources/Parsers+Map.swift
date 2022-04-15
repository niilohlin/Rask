import Foundation

extension Parsers {
    public struct Map<Upstream: Parser, Output>: Parser {
        public let transform: (Upstream.Output) -> Output
        public let upstream: Upstream
        public init(upstream: Upstream, transform: @escaping (Upstream.Output) -> Output) {
            self.transform = transform
            self.upstream = upstream
        }

        public func parse(_ input: Upstream.Input, _ index: inout Upstream.Input.Index) throws -> Output {
            let result = try upstream.parse(input, &index)
            return transform(result)
        }
    }
}

extension Parser {
    public func map<G>(_ transform: @escaping (Output) -> G) -> Parsers.Map<Self, G> {
        Parsers.Map(upstream: self, transform: transform)
    }
}

extension Parsers.Map {
    public func map<G>(_ transform: @escaping (Output) -> G) -> Parsers.Map<Upstream, G> {
        Parsers.Map(upstream: self.upstream, transform: { x in transform(self.transform(x)) } )
    }
}
