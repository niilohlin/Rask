public struct Parser<T> {
    public let name: String = ""
    public let parse: (String, inout String.Index) throws -> T
    public init(_ parse: @escaping (String, inout String.Index) throws -> T) {
        self.parse = parse
    }
}

public protocol Matchable {
    var parser: Parser<Void> { get }
}

extension String: Matchable {
    public var parser: Parser<Void> {
        Parser<String>.string(self).toVoid()
    }
}

extension Character: Matchable {
    public var parser: Parser<Void> {
        Parser<Character>.character(self).toVoid()
    }
}

extension Parser: Matchable where T == Void {
    public var parser: Parser<Void> {
        self
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
        Parser<T> { _, _ in
            throw FailingParser()
        }
    }

    static func always<T>(_ value: T) -> Parser<T> {
        Parser<T> { _, _ in
            value
        }
    }
}

public extension Parser {
    func map<G>(_ transform: @escaping (T) throws -> G) rethrows -> Parser<G> {
        Parser<G> { input, index in
            let result = try self.parse(input, &index)
            return try transform(result)
        }
    }

    func flatMap<G>(_ transform: @escaping (T) throws -> Parser<G>) rethrows -> Parser<G> {
        Parser<G> { input, index in
            var temp = index

            let firstResult = try self.parse(input, &temp)
            let newParser = try transform(firstResult)
            let result = try newParser.parse(input, &temp)
            index = temp
            return result
        }
    }

    func toVoid() -> Parser<Void> {
        map { _ in () }
    }

    func then<G>(_ transform: @escaping () throws -> Parser<G>) rethrows -> Parser<G> {
        try flatMap { _ in
            try transform()
        }
    }
}

public extension Parser {
    struct OrError: UnexpectedToken {
        var expected: String
        var actual: String
    }
    static func or<T>(_ first: Parser<T>, _ second: Parser<T>) -> Parser<T> {
        Parser<T> { input, index in
            let oldIndex = index
            var firstError: Error?
            do {
                return try first.parse(input, &index)
            } catch {
                firstError = error
            }
            do {
                return try second.parse(input, &index)
            } catch {
                print("firstError: \(firstError!)")
                print("secondError: \(error)")
                print("\(input)")
                print(String(repeating: " ", count: oldIndex.utf16Offset(in: input)) + "^")
                if oldIndex >= input.endIndex {
                    throw OrError(expected: "\(first.name) or \(second.name)", actual: "\(input[input.index(before: input.endIndex)])")
                }
                throw OrError(expected: "\(first.name) or \(second.name)", actual: "\(input[oldIndex])")
            }
        }
    }

    func or(_ other: Parser<T>) -> Parser<T> {
        Parser<T>.or(self, other)
    }

    func skip<G>(_ parser: Parser<G>) -> Parser<T> {
        Parser { input, index in
            let value = try self.parse(input, &index)
            _ = try parser.parse(input, &index)
            return value
        }
    }

    func backtrack() -> Parser<T> {
        Parser { input, index in
            var backup = index
            let result = try self.parse(input, &backup)
            index = backup
            return result
        }
    }

    func optional() -> Parser<T?> {
        Parser<T?> { input, index in
            return try? self.parse(input, &index)
        }
    }

    func many() -> Parser<[T]> {
        Parser<[T]> { input, index in
            var result = [T]()
            while true {
                do {
                    let parsed = try self.parse(input, &index)
                    result.append(parsed)
                } catch {
                    break
                }
            }
            return result
        }
    }

    func manyNonEmpty() -> Parser<[T]> {
        Parser<[T]> { input, index in
            var result = [T]()
            while true {
                do {
                    let parsed = try self.parse(input, &index)
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
            `operator`.flatMap { makeOperator -> Parser<T> in
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
        Parser<Character> { input, index in
            let firstChar = input[index]
            guard string.contains(firstChar) else {
                throw NotOneOfError(expected: string, actual: firstChar)
            }
            index = input.index(after: index)
            return firstChar
        }.checkEOF()
    }

    func separated(by separator: Matchable) -> Parser<[T]> {
        separatedNonEmpty(by: separator).or(Parser.always([]))
    }

    func separatedNonEmpty(by separator: Matchable) -> Parser<[T]> {
        let parser = separator.parser
        return flatMap { firstMatch in
            (parser.then { self }).many().map { rest in
                [firstMatch] + rest
            }
        }
    }

    func checkEOF() -> Parser<T> {
        Parser { input, index in

            guard input.endIndex != index else {
                throw AnyUnexpectedToken(expected: "not eof", actual: "")
            }
            return try self.parse(input, &index)
        }
    }

    func lexeme() -> Parser<T> {
        skip(Parser<Character>.character(Character(" ")).or(Parser<Character>.character(Character("\n"))).many())
    }
}

public extension Parser where T == Character {
    struct WrongCharacterError: UnexpectedToken {
        let expected: Character
        var actual: Character
    }

    static func character(_ c: Character) -> Parser<Character> {
        return Parser<Character> { input, index in

            guard input[index] == c else {
                throw WrongCharacterError(expected: c, actual: input[index])
            }
            index = input.index(after: index)
            return c
        }.checkEOF()
    }

    static func digit() -> Parser<Character> {
        return Parser<Character>.one(of: "0123456789")
    }
}

public extension Parser where T == String {
    static func string(_ string: String) -> Parser<String> {
        Parser<String> { input, index in

            guard let end = input.index(index, offsetBy: string.count, limitedBy: input.endIndex) else {
                throw AnyUnexpectedToken(expected: string, actual: input)
            }

            guard String(input[Range(uncheckedBounds: (lower: index, upper: end))]) == string else {
                throw AnyUnexpectedToken(expected: string, actual: input)
            }
            index = end
            return string
        }.checkEOF()
    }
}
