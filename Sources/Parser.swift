
public protocol Parser {
    associatedtype Output
    func parse(_ input: String, _ index: inout String.Index) throws -> Output
}

public struct AnyParser<T>: Parser {
    public typealias Output = T
    private let parseClosure: (String, inout String.Index) throws -> T
    public init(_ parse: @escaping (String, inout String.Index) throws -> T) {
        self.parseClosure = parse
    }

    public func parse(_ str: String, _ index: inout String.Index) throws -> T {
        try parseClosure(str, &index)
    }
}

public protocol Matchable {
    var parser: AnyParser<Void> { get }
}

extension String: Matchable {
    public var parser: AnyParser<Void> {
        Parsers.string(self).toVoid().eraseToAnyParser()
    }
}

extension Character: Matchable {
    public var parser: AnyParser<Void> {
        AnyParser<Character>.character(self).toVoid().eraseToAnyParser()
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
}

public extension Parser {

    func then<G>(_ transform: @escaping () -> AnyParser<G>) -> AnyParser<G> {
        flatMap { _ in
            transform()
        }.eraseToAnyParser()
    }
}
struct OrError: UnexpectedToken {
    var expected: String
    var actual: String
}

func or<P: Parser, P2: Parser>(_ first: P, _ second: P2) -> AnyParser<P.Output> where P.Output == P2.Output  {
    AnyParser<P.Output> { input, index in
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
//                    throw OrError(expected: "or \(first.name) or \(second.name)", actual: "\(input[input.index(before: input.endIndex)])")
                throw OrError(expected: " or ", actual: "\(input[input.index(before: input.endIndex)])")
            }
            throw OrError(expected: " or ", actual: "\(input[oldIndex])")
//                throw OrError(expected: "\(first.name) or \(second.name)", actual: "\(input[oldIndex])")
        }
    }
}

struct NotOneOfError: UnexpectedToken {
    let expected: String
    let actual: Character
}

public extension Parser {
    func or<POther: Parser>(_ other: POther) -> AnyParser<Output> where Self.Output == POther.Output {
        Rask.or(self, other)
    }

    func skip<G>(_ parser: AnyParser<G>) -> AnyParser<Output> {
        AnyParser { input, index in
            let value = try self.parse(input, &index)
            _ = try parser.parse(input, &index)
            return value
        }
    }

    func backtrack() -> AnyParser<Output> {
        AnyParser { input, index in
            var backup = index
            let result = try self.parse(input, &backup)
            index = backup
            return result
        }
    }

    func optional() -> AnyParser<Output?> {
        AnyParser<Output?> { input, index in
            return try? self.parse(input, &index)
        }
    }

    func many() -> AnyParser<[Output]> {
        AnyParser<[Output]> { input, index in
            var result = [Output]()
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

    func manyNonEmpty() -> AnyParser<[Output]> {
        AnyParser<[Output]> { input, index in
            var result = [Output]()
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

    func chainLeft(`operator`: AnyParser<(Output, Output) -> Output>) -> AnyParser<Output> {
        func chain(lhs: Output) -> AnyParser<Output> {
            `operator`.flatMap { makeOperator -> AnyParser<Output> in
                self.flatMap { rhs -> AnyParser<Output> in
                    let result = makeOperator(lhs, rhs)
                    return chain(lhs: result)
                }.eraseToAnyParser()
            }.or(Parsers.always(lhs))
        }
        return self.flatMap { lhs in
            chain(lhs: lhs)
        }.eraseToAnyParser()
    }

    static func one(of string: String) -> AnyParser<Character> {
        AnyParser<Character> { input, index in
            let firstChar = input[index]
            guard string.contains(firstChar) else {
                throw NotOneOfError(expected: string, actual: firstChar)
            }
            index = input.index(after: index)
            return firstChar
        }.checkEOF().eraseToAnyParser()
    }

    func separated(by separator: Matchable) -> AnyParser<[Output]> {
        separatedNonEmpty(by: separator).or(Parsers.always([]))
    }

    func separatedNonEmpty(by separator: Matchable) -> AnyParser<[Output]> {
        let parser = separator.parser
        return flatMap { firstMatch in
            (parser.then { self.eraseToAnyParser() }).many().map { rest in
                [firstMatch] + rest
            }.eraseToAnyParser()
        }.eraseToAnyParser()
    }

    func checkEOF() -> EOFSafeParser<Self> {
        EOFSafeParser(upstream: self)
    }

    func lexeme() -> AnyParser<Output> {
        skip(AnyParser<Character>.character(Character(" ")).or(AnyParser<Character>.character(Character("\n"))).many())
    }

    func eraseToAnyParser() -> AnyParser<Output> {
        AnyParser(parse(_:_:))
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
        return try upstream.parse(input, &index)
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
        }.checkEOF().eraseToAnyParser()
    }

    static func digit() -> AnyParser<Character> {
        return AnyParser<Character>.one(of: "0123456789")
    }
}
