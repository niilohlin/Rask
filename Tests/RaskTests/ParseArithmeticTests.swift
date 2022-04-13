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
extension AnyParser {
    static func number() -> AnyParser<Int> {
        Parsers.digit().manyNonEmpty().map { Int(String($0))! }.eraseToAnyParser()
    }
}

// parse
extension AnyParser {
    static func expressionNumber() -> AnyParser<Expr> {
        AnyParser.number().lexeme().map(Expr.number).eraseToAnyParser()
    }

    static func term() -> AnyParser<Expr> {
        AnyParser<Expr> { input, index in
            try expressionNumber().or(parseParens()).or(AnyParser<Expr>.expressionAdd()).parse(input, &index)
        }
    }

    static func expressionAdd() -> AnyParser<Expr> {
        term().flatMap { lhs in
            Parsers.character("+").lexeme().then {
                parseExpression().map { rhs in
                    Expr.add(lhs, rhs)
                }.eraseToAnyParser()
            }
        }.eraseToAnyParser()
    }

    static func parseParens() -> AnyParser<Expr> {
        Parsers.character("(").lexeme().then {
            AnyParser<Expr>.parseExpression().flatMap { number in
                Parsers.character(")").lexeme().map { _ in
                    Expr.parentheses(number)
                }
            }
        }.eraseToAnyParser()
    }

    static func parseExpression() -> AnyParser<Expr> {
        term().chainLeft(
            Parsers.character("+").lexeme().map { _ in
                Expr.add
            }
        ).eraseToAnyParser()
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
        try runExample(examples: examples, parser: AnyParser<Expr>.parseParens())
    }

    func testAdd() throws {
        let examples: [(String, Expr)] = [
            ("1+5", .add(.number(1), .number(5))),
            ("1 +5 ", .add(.number(1), .number(5))),
            ("1+ 5 ", .add(.number(1), .number(5))),
            ("1 + 5", .add(.number(1), .number(5)))
        ]
        try runExample(examples: examples, parser: AnyParser<Expr>.expressionAdd())
    }

    func testAnyParser() throws {
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
        try runExample(examples: examples, parser: AnyParser<Expr>.parseExpression())
    }
}
