import Foundation

extension Parsers {
    public struct ChainLeft<Upstream: Parser, Operator: Parser>: Parser where
    Operator.Output == ((Upstream.Output, Upstream.Output) -> Upstream.Output), Upstream.Input == Operator.Input {
        public let `operator`: Operator
        public let upstream: Upstream
        public init(upstream: Upstream, `operator`: Operator) {
            self.upstream = upstream
            self.operator = `operator`
        }

        public func parse(_ input: Upstream.Input, _ index: inout Upstream.Input.Index) throws -> Upstream.Output {
            func chain(lhs: Output) -> AnyParser<Upstream.Input, Output> {
                `operator`.flatMap { makeOperator in
                    upstream.flatMap { rhs -> AnyParser<Upstream.Input, Output> in
                        let result = makeOperator(lhs, rhs)
                        return chain(lhs: result)
                    }
                }.or(Parsers.always(lhs)).eraseToAnyParser()
            }

            return try upstream.flatMap { lhs in
                chain(lhs: lhs)
            }.parse(input, &index)
        }
    }
}

extension Parser {
    public func chainLeft<Operator: Parser>(_ `operator`: Operator) -> Parsers.ChainLeft<Self, Operator> where Operator.Output == ((Output, Output) -> Output) {
        Parsers.ChainLeft(upstream: self, operator: `operator`)
    }
}
//func chainLeft(`operator`: AnyParser<(Output, Output) -> Output>) -> AnyParser<Output> {
//}

