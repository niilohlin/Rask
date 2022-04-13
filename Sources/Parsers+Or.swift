import Foundation

extension Parsers {
    public struct Or<LUpstream: Parser, RUpstream: Parser>: Parser where LUpstream.Output == RUpstream.Output {
        public typealias Output = LUpstream.Output

        public let lUpstream: LUpstream
        public let rUpstream: RUpstream
        init(lUpstream: LUpstream, rUpstream: RUpstream) {
            self.lUpstream = lUpstream
            self.rUpstream = rUpstream
        }

        public func parse(_ input: String, _ index: inout String.Index) throws -> Output {
            let oldIndex = index
            var firstError: Error?
            do {
                return try lUpstream.parse(input, &index)
            } catch {
                firstError = error
            }
            do {
                return try rUpstream.parse(input, &index)
            } catch {
//                print("firstError: \(firstError!)")
//                print("secondError: \(error)")
//                print("\(input)")
//                print(String(repeating: " ", count: oldIndex.utf16Offset(in: input)) + "^")
                let expectedText = "\(String(describing: LUpstream.self)) or \(String(describing: RUpstream.self))"
                if oldIndex >= input.endIndex {
                    throw OrError(expected: expectedText, actual: "\(input[input.index(before: input.endIndex)])")
                }
                throw OrError(expected: expectedText, actual: "\(input[oldIndex])")
            }
        }
    }
}

extension Parser {
    public func or<Other: Parser>(_ other: Other) -> Parsers.Or<Self, Other> where Self.Output == Other.Output {
        Parsers.Or(lUpstream: self, rUpstream: other)
    }
}
