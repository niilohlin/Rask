
public struct Parser<T> {
    public let parse: (inout String) throws -> T
    public init(_ parse: @escaping (inout String) throws -> T) {
        self.parse = parse
    }
}

protocol UnexpectedToken: Error {
    associatedtype Expected
    associatedtype Actual
    var expected: Expected { get }
    var actual: Actual { get }
}
public extension Parser {
    struct AnyUnexpectedToken<ExpectedToken>: UnexpectedToken {
        let expected: ExpectedToken
        let actual: ExpectedToken
    }
}

public extension Parser {
    struct FailingParser: Error {
    }
    static func failingParser<T>(_ type: T.Type) -> Parser<T> {
        return Parser<T> { _ in
            throw FailingParser()
        }
    }

    static func always<T>(_ value: T) -> Parser<T> {
        return Parser<T> { _ in
            return value
        }
    }
}

public extension Parser {
    func map<G>(_ transform: @escaping (T) throws -> G) rethrows -> Parser<G> {
        return Parser<G> { input in
            let result = try self.parse(&input)
            return try transform(result)
        }
    }

    func flatMap<G>(_ transform: @escaping (T) throws -> Parser<G>) rethrows -> Parser<G> {
        return Parser<G> { input in
            var temp = input

            let firstResult = try self.parse(&temp)
            let newParser = try transform(firstResult)
            let result = try newParser.parse(&temp)
            input = temp
            return result
        }
    }

    func then<G>(_ transform: @escaping () throws -> Parser<G>) rethrows -> Parser<G> {
        return try flatMap { _ in
            try transform()
        }
    }
}

public extension Parser {
    static func or<T>(_ first: Parser<T>, _ second: Parser<T>) -> Parser<T> {
        return Parser<T> { input in
            do {
                return try first.parse(&input)
            } catch {
                return try second.parse(&input)
            }
        }
    }

    func or(_ other: Parser<T>) -> Parser<T> {
        return Parser<T>.or(self, other)
    }

    func skip<G>(_ parser: Parser<G>) -> Parser<T> {
        return Parser { input in
            let value = try self.parse(&input)
            _ = try parser.parse(&input)
            return value
        }
    }

    func backtrack() -> Parser<T> {
        return Parser { input in
            var backup = input
            let result = try self.parse(&backup)
            input = backup
            return result
        }
    }

    func optional() -> Parser<T?> {
        return Parser<T?> { input in
            return try? self.parse(&input)
        }
    }

    func many() -> Parser<[T]> {
        return Parser<[T]> { input in
            var result = [T]()
            while true {
                do {
                    let parsed = try self.parse(&input)
                    result.append(parsed)
                } catch {
                    break
                }
            }
            return result
        }
    }

    func manyNonEmpty() -> Parser<[T]> {
        return Parser<[T]> { input in
            var result = [T]()
            while true {
                do {
                    let parsed = try self.parse(&input)
                    result.append(parsed)
                } catch {
                    if result.isEmpty {
                        throw error
                    }
                    break
                }
            }
            return result
        }
    }

    func chainLeft(`operator`: Parser<(T, T) -> T>) -> Parser<T> {
        func chain(lhs: T) -> Parser<T> {
            return `operator`.flatMap { makeOperator -> Parser<T> in
                self.flatMap { rhs -> Parser<T> in
                    let result = makeOperator(lhs, rhs)
                    return chain(lhs: result)
                }
            }.or(Parser<T>.always(lhs))
        }
        return self.flatMap { lhs in
            chain(lhs: lhs)
        }
    }

    struct NotOneOfError: UnexpectedToken {
        let expected: String
        let actual: Character
    }

    static func one(of string: String) -> Parser<Character> {
        return Parser<Character> { input in
            let firstChar = Character(String(input.prefix(1)))
            guard string.contains(firstChar) else {
                throw NotOneOfError(expected: string, actual: firstChar)
            }
            input = String(input.dropFirst())
            return firstChar
        }.checkEOF()
    }

    func checkEOF() -> Parser<T> {
        return Parser { input in
            guard !input.isEmpty else {
                throw AnyUnexpectedToken(expected: "not eof", actual: "")
            }
            return try self.parse(&input)
        }
    }

    func lexeme() -> Parser<T> {
        return skip(Parser<Character>.character(Character(" ")).or(Parser<Character>.character(Character("\n"))).many())
    }
}

public extension Parser where T == Character {
    struct WrongCharacterError: UnexpectedToken {
        let expected: Character
        var actual: Character
    }
    static func character(_ c: Character) -> Parser<Character> {
        return Parser<Character> { input in
            guard String(input.prefix(1)) == String(c) else {
                throw WrongCharacterError(expected: c, actual: input.first!)
            }
            input = String(input.dropFirst())
            return c
        }.checkEOF()
    }

    static func digit() -> Parser<Character> {
        return Parser<Character>.one(of: "0123456789")
    }
}

public extension Parser where T == String {
    static func string(_ string: String) -> Parser<String> {
        return Parser<String> { input in
            guard input.hasPrefix(string) else {
                throw AnyUnexpectedToken(expected: string, actual: input)
            }
            input = String(input.dropFirst(string.count))
            return string
        }.checkEOF()
    }
}
