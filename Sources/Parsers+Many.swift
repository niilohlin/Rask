import Foundation

extension Parsers {
    public struct Many<Upstream: Parser>: Parser {
        public let upstream: Upstream
        public init(upstream: Upstream) {
            self.upstream = upstream
        }

        public func parse(_ input: String, _ index: inout String.Index) throws -> [Upstream.Output] {
            var result = [Upstream.Output]()
            while true {
                do {
                    let parsed = try upstream.parse(input, &index)
                    result.append(parsed)
                } catch {
                    break
                }
            }
            return result
        }
    }
}

extension Parser {
    public func many() -> Parsers.Many<Self> {
        Parsers.Many(upstream: self)
    }
}
