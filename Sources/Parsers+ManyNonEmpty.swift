import Foundation

extension Parsers {
    public struct ManyNonEmpty<Upstream: Parser>: Parser {
        public let upstream: Upstream
        public init(upstream: Upstream) {
            self.upstream = upstream
        }

        public func parse(_ input: Upstream.Input, _ index: inout Upstream.Input.Index) throws -> [Upstream.Output] {
            var result = [Upstream.Output]()
            while true {
                do {
                    let parsed = try upstream.parse(input, &index)
                    result.append(parsed)
                } catch {
                    if result.isEmpty {
                        throw error
                    }
                    break
                }
            }
            return result
        }
    }
}

extension Parser {
    public func manyNonEmpty() -> Parsers.ManyNonEmpty<Self> {
        Parsers.ManyNonEmpty(upstream: self)
    }
}
