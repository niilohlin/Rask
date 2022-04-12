import XCTest
import Rask

indirect enum Expr {
    case number(Int)
    case add(Expr, Expr)
    case mul(Expr, Expr)
    case parentheses(Expr)
}

extension Expr: Equatable {
    public static func == (lhs: Expr, rhs: Expr) -> Bool {
        switch (lhs, rhs) {
        case (.number(let l), .number(let r)):
            return l == r
        case let (.add(lExpr), .add(rExpr)):
            return lExpr == rExpr
        case let (.mul(lExpr), .mul(rExpr)):
            return lExpr == rExpr
        case (.parentheses(let lExpr), .parentheses(let rExpr)):
            return lExpr == rExpr
        default:
            return false
        }
    }
}

// lex
extension Parser {
    static func number() -> Parser<Int> {
        Parser<Character>.digit().manyNonEmpty().map { Int(String($0))! }
    }
}

// parse
extension Parser {
    static func expressionNumber() -> Parser<Expr> {
        Parser.number().lexeme().map(Expr.number)
    }

    static func term() -> Parser<Expr> {
        Parser<Expr> { input, index in
            try expressionNumber().or(parseParens()).or(Parser<Expr>.expressionAdd()).parse(input, &index)
        }
    }

    static func expressionAdd() -> Parser<Expr> {
        term().flatMap { lhs in
            Parser<Character>.character(Character("+")).lexeme().then {
                parseExpression().map { rhs in
                    Expr.add(lhs, rhs)
                }
            }
        }
    }

    static func parseParens() -> Parser<Expr> {
        Parser<Character>.character(Character("(")).lexeme().then {
            Parser<Expr>.parseExpression().flatMap { number in
                Parser<Character>.character(Character(")")).lexeme().map { _ in
                    Expr.parentheses(number)
                }
            }
        }
    }

    static func parseExpression() -> Parser<Expr> {
        term().chainLeft(operator: Parser<Character>.character(Character("+")).lexeme().map { _ in
            Expr.add
        })
    }
}

final class ParseArithmeticTests: XCTestCase {

    func testParentheses() throws {
        let examples: [(String, Expr)] = [
            ("(1)", .parentheses(.number(1))),
            ("(23)", .parentheses(.number(23))),
            ("( 5)", .parentheses(.number(5))),
            ("(3 )", .parentheses(.number(3))),
            ("( 0 ) ", .parentheses(.number(0))),
            ("((0)) ", .parentheses(.parentheses(.number(0))))
        ]
        try runExample(examples: examples, parser: Parser<Expr>.parseParens())
    }

    func testAdd() throws {
        let examples: [(String, Expr)] = [
            ("1+5", .add(.number(1), .number(5))),
            ("1 +5 ", .add(.number(1), .number(5))),
            ("1+ 5 ", .add(.number(1), .number(5))),
            ("1 + 5", .add(.number(1), .number(5)))
        ]
        try runExample(examples: examples, parser: Parser<Expr>.expressionAdd())
    }

    func testParser() throws {
        let examples: [(String, Expr)] = [
            ("1", .number(1)),
            ("23", .number(23)),
            ("5 + 3", .add(.number(5), .number(3))),
            ("(5 )", .parentheses(.number(5))),
            ("((0)) ", .parentheses(.parentheses(.number(0)))),
            ("(0 + 5) ", .parentheses(.add(.number(0), .number(5)))),
            ("1 + 2 + 3", .add(.add(.number(1), .number(2)), .number(3))),
            ("1 + (2 + 3)", .add(.number(1), .parentheses(.add(.number(2), .number(3)))))
        ]
        try runExample(examples: examples, parser: Parser<Expr>.parseExpression())
    }
}
