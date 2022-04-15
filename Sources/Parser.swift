
public protocol Parser {
    associatedtype Output
    associatedtype Input: Collection
    func parse(_ input: Input, _ index: inout Input.Index) throws -> Output
}


public struct AnyParser<Input: Collection, T>: Parser {
    public typealias Output = T
    private let parseClosure: (Input, inout Input.Index) throws -> T
    public init(_ parse: @escaping (Input, inout Input.Index) throws -> T) {
        self.parseClosure = parse
    }

    public func parse(_ str: Input, _ index: inout Input.Index) throws -> T {
        try parseClosure(str, &index)
    }
}

public extension Parser {
    func eraseToAnyParser() -> AnyParser<Input, Output> {
        AnyParser(parse(_:_:))
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
//    static func failingAnyParser<T>(_ type: T.Type) -> AnyParser<T> {
//        AnyParser<T> { _, _ in
//            throw FailingAnyParser()
//        }
//    }
}

struct OrError: UnexpectedToken {
    var expected: String
    var actual: String
}

struct NotOneOfError<Expected: Sequence>: UnexpectedToken {
    let expected: Expected
    let actual: Expected.Element
}

