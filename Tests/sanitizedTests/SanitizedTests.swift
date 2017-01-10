import XCTest
@testable import Sanitized

class sanitizedTests: XCTestCase {
    static let allTests = [
        ("testExample", testExample)
    ]
    
    func testExample() {
        XCTAssertEqual(2+2, 4)
    }
}
