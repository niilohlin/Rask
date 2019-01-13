
public struct Parser<T> {
    public let parse: (inout String) throws -> T
}


public extension Parser {
    struct FailingParser: Error {
    }
    static func failingParser<T>(_ type: T.Type) -> Parser<T> {
        return Parser<T> { _ in
            throw FailingParser()
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

//    func apply<G>(_ other: Parser<(T) -> G>) -> Parser<G> {
//
//    }

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

    func lexeme() -> Parser<T> {
        return skip(Parser<Character>.character(Character(" ")).or(Parser<Character>.character(Character("\n"))).many())
    }
}

public extension Parser where T == Character {
    struct WrongCharacterError: Error {
    }
    static func character(_ c: Character) -> Parser<Character> {
        return Parser<Character> { input in
            guard String(input.prefix(1)) == String(c) else {
                throw WrongCharacterError()
            }
            input = String(input.dropFirst())
            return c
        }
    }
}
