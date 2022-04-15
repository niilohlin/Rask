import Foundation
import XCTest
import Rask

extension Parser where Input == String {
    func parse(input: String) throws -> Output {
        let input = input
        var index = input.startIndex
        return try self.parse(input, &index)
    }
}

extension XCTestCase {
    func runExample<T: Equatable>(examples: [(String, T)], parser: AnyParser<String, T>, file: StaticString = #file, line: UInt = #line) throws {
        for (input, expected) in examples {
            let input = input
            var index = input.startIndex

            XCTAssertEqual(try parser.parse(input, &index), expected, file: file, line: line)
            XCTAssertEqual(index, input.endIndex, "input was not consumed. rest: \(input)", file: file, line: line)
        }
    }
}
