import Foundation

extension Parsers {
    public struct FlatMap<Upstream: Parser, Downstream: Parser>: Parser {
        public let transform: (Upstream.Output) -> Downstream
        public let upstream: Upstream

        public init(upstream: Upstream, transform: @escaping (Upstream.Output) -> Downstream) {
            self.transform = transform
            self.upstream = upstream
        }

        public func parse(_ input: String, _ index: inout String.Index) throws -> Downstream.Output {
            var temp = index
            let firstResult = try upstream.parse(input, &temp)
            let newAnyParser = transform(firstResult)
            let result = try newAnyParser.parse(input, &temp)
            index = temp
            return result

        }
    }
}

extension Parser {
    public func flatMap<Downstream: Parser>(_ transform: @escaping (Output) -> Downstream) -> Parsers.FlatMap<Self, Downstream> {
        Parsers.FlatMap(upstream: self, transform: transform)
    }
}
