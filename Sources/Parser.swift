
public protocol Parser {
    associatedtype Output
    func parse(_ input: String, _ index: inout String.Index) throws -> Output
}

public struct AnyParser<T>: Parser {
    typealias Output = T
    private let parseClosure: (String, inout String.Index) throws -> T
    public init(_ parse: @escaping (String, inout String.Index) throws -> T) {
        self.parseClosure = parse
    }

    func parse(_ str: String, _ index: inout String.Index) throws -> T {
        try parseClosure(str, &index)
    }
}

public protocol Matchable {
    var parser: AnyParser<Void> { get }
}

extension String: Matchable {
    public var parser: AnyParser<Void> {
        AnyParser<String>.string(self).toVoid()
    }
}

extension Character: Matchable {
    public var parser: AnyParser<Void> {
        AnyParser<Character>.character(self).toVoid()
    }
}

extension AnyParser: Matchable where T == Void {
    public var parser: AnyParser<Void> {
        self
    }
}

protocol UnexpectedToken: Error {
    associatedtype Expected
    associatedtype Actual
    var expected: Expected { get }
    var actual: Actual { get }
}
public extension AnyParser {
}
struct AnyUnexpectedToken<ExpectedToken>: UnexpectedToken {
    let expected: ExpectedToken
    let actual: ExpectedToken
}

public extension AnyParser {
    struct FailingAnyParser: Error {
    }
    static func failingAnyParser<T>(_ type: T.Type) -> AnyParser<T> {
        AnyParser<T> { _, _ in
            throw FailingAnyParser()
        }
    }

    static func always<T>(_ value: T) -> AnyParser<T> {
        AnyParser<T> { _, _ in
            value
        }
    }
}

public extension AnyParser {
    func map<G>(_ transform: @escaping (T) throws -> G) rethrows -> AnyParser<G> {
        AnyParser<G> { input, index in
            let result = try self.parse(input, &index)
            return try transform(result)
        }
    }

    func flatMap<G>(_ transform: @escaping (T) throws -> AnyParser<G>) rethrows -> AnyParser<G> {
        AnyParser<G> { input, index in
            var temp = index

            let firstResult = try self.parse(input, &temp)
            let newAnyParser = try transform(firstResult)
            let result = try newAnyParser.parse(input, &temp)
            index = temp
            return result
        }
    }

    func toVoid() -> AnyParser<Void> {
        map { _ in () }
    }

    func then<G>(_ transform: @escaping () throws -> AnyParser<G>) rethrows -> AnyParser<G> {
        try flatMap { _ in
            try transform()
        }
    }
}

public extension AnyParser {
    struct OrError: UnexpectedToken {
        var expected: String
        var actual: String
    }
    static func or<T>(_ first: AnyParser<T>, _ second: AnyParser<T>) -> AnyParser<T> {
        AnyParser<T> { input, index in
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

    func or(_ other: AnyParser<T>) -> AnyParser<T> {
        AnyParser<T>.or(self, other)
    }

    func skip<G>(_ parser: AnyParser<G>) -> AnyParser<T> {
        AnyParser { input, index in
            let value = try self.parse(input, &index)
            _ = try parser.parse(input, &index)
            return value
        }
    }

    func backtrack() -> AnyParser<T> {
        AnyParser { input, index in
            var backup = index
            let result = try self.parse(input, &backup)
            index = backup
            return result
        }
    }

    func optional() -> AnyParser<T?> {
        AnyParser<T?> { input, index in
            return try? self.parse(input, &index)
        }
    }

    func many() -> AnyParser<[T]> {
        AnyParser<[T]> { input, index in
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

    func manyNonEmpty() -> AnyParser<[T]> {
        AnyParser<[T]> { input, index in
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

    func chainLeft(`operator`: AnyParser<(T, T) -> T>) -> AnyParser<T> {
        func chain(lhs: T) -> AnyParser<T> {
            `operator`.flatMap { makeOperator -> AnyParser<T> in
                self.flatMap { rhs -> AnyParser<T> in
                    let result = makeOperator(lhs, rhs)
                    return chain(lhs: result)
                }
            }.or(AnyParser<T>.always(lhs))
        }
        return self.flatMap { lhs in
            chain(lhs: lhs)
        }
    }

    struct NotOneOfError: UnexpectedToken {
        let expected: String
        let actual: Character
    }

    static func one(of string: String) -> AnyParser<Character> {
        AnyParser<Character> { input, index in
            let firstChar = input[index]
            guard string.contains(firstChar) else {
                throw NotOneOfError(expected: string, actual: firstChar)
            }
            index = input.index(after: index)
            return firstChar
        }.checkEOF()
    }

    func separated(by separator: Matchable) -> AnyParser<[T]> {
        separatedNonEmpty(by: separator).or(AnyParser.always([]))
    }

    func separatedNonEmpty(by separator: Matchable) -> AnyParser<[T]> {
        let parser = separator.parser
        return flatMap { firstMatch in
            (parser.then { self }).many().map { rest in
                [firstMatch] + rest
            }
        }
    }

    func checkEOF() -> AnyParser<T> {
        AnyParser { input, index in
        }
    }

    func lexeme() -> AnyParser<T> {
        skip(AnyParser<Character>.character(Character(" ")).or(AnyParser<Character>.character(Character("\n"))).many())
    }
}

public struct EOFSafeParser<Upstream: Parser>: Parser {
    public typealias Output = Upstream.Output
    public let upstream: Upstream
    public init(upstream: Upstream) {
        self.upstream = upstream
    }

    public func parse(_ input: String, _ index: inout String.Index) throws -> Upstream.Output {
        guard input.endIndex > index else {
            throw AnyUnexpectedToken(expected: "not eof", actual: "")
        }
        return try self.parse(input, &index)
    }
}

public extension AnyParser where T == Character {
    struct WrongCharacterError: UnexpectedToken {
        let expected: Character
        var actual: Character
    }

    static func character(_ c: Character) -> AnyParser<Character> {
        return AnyParser<Character> { input, index in

            guard input[index] == c else {
                throw WrongCharacterError(expected: c, actual: input[index])
            }
            index = input.index(after: index)
            return c
        }.checkEOF()
    }

    static func digit() -> AnyParser<Character> {
        return AnyParser<Character>.one(of: "0123456789")
    }
}

public struct StringParser: Parser {
    typealias Output = String
    let string: String
    public init(string: String) {
        self.string = string
    }

    func parse(_ input: String, _ index: inout String.Index) throws -> String {
        EOFSafeParser(upstream: AnyParser.always(()))
        guard let end = input.index(index, offsetBy: string.count, limitedBy: input.endIndex) else {
            throw AnyUnexpectedToken(expected: string, actual: input)
        }

        guard String(input[Range(uncheckedBounds: (lower: index, upper: end))]) == string else {
            throw AnyUnexpectedToken(expected: string, actual: input)
        }
        index = end
        return string
    }
}
public extension AnyParser where T == String {
    static func string(_ string: String) -> AnyParser<String> {
        AnyParser<String> { input, index in
        }.checkEOF()
    }
}
