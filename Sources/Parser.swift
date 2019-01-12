
struct Parser<T> {
    let parse: (inout String) throws -> T
}

extension Parser where T == Character {
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
