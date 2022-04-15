import Foundation

extension Parsers {
    public struct Then<Upstream: Parser, Downstream: Parser>: Parser where Upstream.Input == Downstream.Input {
        public let transform: () -> Downstream
        public let upstream: Upstream

        public init(upstream: Upstream, transform: @escaping () -> Downstream) {
            self.transform = transform
            self.upstream = upstream
        }

        public func parse(_ input: Upstream.Input, _ index: inout Upstream.Input.Index) throws -> Downstream.Output {
            var temp = index
            _ = try upstream.parse(input, &temp)
            let newParser = transform()
            let result = try newParser.parse(input, &temp)
            index = temp
            return result

        }
    }
}

extension Parser {
    public func then<Downstream: Parser>(_ transform: @escaping () -> Downstream) -> Parsers.Then<Self, Downstream> {
        Parsers.Then(upstream: self, transform: transform)
    }
}
