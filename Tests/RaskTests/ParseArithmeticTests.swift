import XCTest
import Rask

extension Parser {
    func parse(input: String) throws -> T {
        var input = input
        return try self.parse(&input)
    }
}

indirect enum Expr {
    case number(Int)
    case add(Expr, Expr)
    case mul(Expr, Expr)
}

extension Expr: Equatable {
    public static func == (lhs: Expr, rhs: Expr) -> Bool {
        switch (lhs, rhs) {
        case (.number(let l), .number(let r)):
            return l == r
        case (.add(let lExpr), .add(let rExpr)):
            return lExpr == rExpr
        case (.mul(let lExpr), .mul(let rExpr)):
            return lExpr == rExpr
        default:
            return false
        }
    }
}

final class ParseArithmeticTests: XCTestCase {
    let examples: [(String, Expr)] = [
        ("1", .number(1)),
        ("23", .number(23))
    ]


}
