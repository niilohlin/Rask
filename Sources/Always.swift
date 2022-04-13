
import Foundation


extension Parsers {
    public struct Always<T>: Parser {
        public typealias Output = T
        public let value: T
        public init(_ value: T) {
            self.value = value
        }

        public func parse(_ input: String, _ index: inout String.Index) throws -> T {
            value
        }
    }

    static func always<T>(_ value: T) -> Always<T> {
        Always(value)
    }
}
