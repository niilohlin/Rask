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

struct Parentheses: Equatable {
    let integer: Int
}

// lex
extension Parser {
    static func number() -> Parser<Int> {
        return Parser<Character>.digit().manyNonEmpty().map { Int(String($0))! }
    }
}

// parse
extension Parser {
    static func expressionNumber() -> Parser<Expr> {
        return Parser.number().lexeme().map(Expr.number)
    }

    static func parseExpression() -> Parser<Expr> {
        return Parser.expressionNumber()
    }

    static func parseParens() -> Parser<Parentheses> {
        return Parser<Character>.character(Character("(")).flatMap { _ in
            Parser<Int>.number().flatMap { number in
                Parser<Character>.character(Character(")")).map { _ in
                    Parentheses(integer: number)
                }
            }
        }
    }
}

final class ParseArithmeticTests: XCTestCase {

    func runExample<T: Equatable>(examples: [(String, T)], parser: Parser<T>, file: StaticString = #file, line: UInt = #line) throws {
        for (input, expected) in examples {
            XCTAssertEqual(try parser.parse(input: input), expected, file: file, line: line)
        }
    }

    func testParser() throws {
        let examples: [(String, Expr)] = [
            ("1", .number(1)),
            ("23", .number(23))
        ]
        try runExample(examples: examples, parser: Parser<Expr>.parseExpression())
    }

    func testParentheses() throws {
        let examples: [(String, Parentheses)] = [
            ("(1)", Parentheses(integer: 1)),
            ("(23)", Parentheses(integer: 23))
        ]
        try runExample(examples: examples, parser: Parser<Parentheses>.parseParens())
    }
}
