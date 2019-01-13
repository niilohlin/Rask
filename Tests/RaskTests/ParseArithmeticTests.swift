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

    var expressionParser: Parser<Expr>!

    override func setUp() {
        super.setUp()

        let intParser = Parser<Expr>.or(
                Parser<Character>.character(Character("1")),
                Parser<Character>.character(Character("2"))
        ).map { char in
            Expr.number(Int(String(char))!)
        }.lexeme()


        expressionParser = intParser
    }

    func testParseInt() throws {
        let result = try expressionParser.parse(input: "1")
        XCTAssertEqual(result, Expr.number(1))
    }

    func testParseIntWithTrailingWhiteSpace() throws {
        var input = "1  "
        let result = try expressionParser.parse(&input)
        XCTAssertEqual(result, Expr.number(1))
        XCTAssertEqual(input, "")
    }

    func testParserMultiplication() throws {
        let result = try expressionParser.parse(input: "1 * 2")
        XCTAssertEqual(result, Expr.mul(Expr.number(1), Expr.number(2)))
    }

    func testParseArithmetic() throws {
        let expression = "(1 + 2) * 2 + 1"




//        let parenParser = Parser<Expr> { input in
//
//        }
    }
}
