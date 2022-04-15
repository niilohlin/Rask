
import Foundation


extension Parsers {
    public struct Always<Input: Collection, T>: Parser {
        public typealias Output = T
        public let value: T
        public init(_ value: T) {
            self.value = value
        }

        public func parse(_ input: Input, _ index: inout Input.Index) throws -> T {
            value
        }
    }

    static func always<Input: Collection, T>(_ value: T) -> Always<Input, T> {
        Always(value)
    }
}
