import Foundation

extension Parsers {
    public struct Or<LUpstream: Parser, RUpstream: Parser>: Parser where LUpstream.Input == RUpstream.Input,
                                                                         LUpstream.Output == RUpstream.Output {
        public typealias Output = RUpstream.Output

        public let lUpstream: LUpstream
        public let rUpstream: RUpstream
        init(lUpstream: LUpstream, rUpstream: RUpstream) {
            self.lUpstream = lUpstream
            self.rUpstream = rUpstream
        }

        public func parse(_ input: LUpstream.Input, _ index: inout RUpstream.Input.Index) throws -> Output {
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
                throw OrError(expected: expectedText, actual: "\(input[input.index(oldIndex, offsetBy: 0, limitedBy: input.endIndex) ?? input.endIndex])")
            }
        }
    }
}

extension Parser {
    public func or<Other: Parser>(_ other: Other) -> Parsers.Or<Self, Other> where Self.Output == Other.Output, Self.Input == Other.Input {
        Parsers.Or(lUpstream: self, rUpstream: other)
    }
}
