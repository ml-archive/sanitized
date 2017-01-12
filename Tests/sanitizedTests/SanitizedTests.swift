import XCTest
import HTTP
import Vapor

@testable import Sanitized

class SanitizedTests: XCTestCase {
    static let allTests = [
        ("testBasic", testBasic)
    ]
    
    func testBasic() {
        let request = buildRequest(body: [
            "id": 1,
            "name": "Brett",
            "email": "test@tested.com"
        ])
        
        expectNoThrow() {
            let model: TestModel = try request.extractModel()
            XCTAssertNil(model.id)
            XCTAssertEqual(model.name, "Brett")
            XCTAssertEqual(model.email, "test@tested.com")
        }
    }
    
    func testBasicFailed() {
        let request = buildInvalidRequest()
        expect(toThrow: Abort.badRequest) {
            let _: TestModel = try request.extractModel()
        }
    }
    
    func testUpdatedError() {
        let request = buildRequest(body: [
            "email": "test@tested.com"
        ])
        
        expect(toThrow: Abort.custom(status: .badRequest, message: "Username not provided.")) {
            let _: TestModel = try request.extractModel()
        }
    }
    
    func testPermitted() {
        let json = JSON([
            "id": 1,
            "name": "Brett",
            "email": "test@tested.com"
        ])
        
        let result = json.permit(["name"])
        XCTAssertNil(result["id"])
        XCTAssertEqual(result["name"]?.string, "Brett")
        XCTAssertNil(result["email"])
    }
    
    func testEmptyPermitted() {
        let json = JSON([
            "id": 1,
            "name": "Brett",
            "email": "test@tested.com"
        ])
        
        let result = json.permit([])
        XCTAssertNil(result["id"])
        XCTAssertNil(result["name"])
        XCTAssertNil(result["email"])
    }
}

extension SanitizedTests {
    func buildRequest(body: Node) -> Request {
        let body = try! JSON(node: body).makeBytes()
        
        return try! Request(
            method: .post,
            uri: "/test",
            headers: [
                "Content-Type": "application/json"
            ],
            body: .data(body)
        )
    }
    
    func buildInvalidRequest() -> Request {
        return try! Request(
            method: .post,
            uri: "/test"
        )
    }
}

struct TestModel: Model, Sanitizable {
    var id: Node?
    
    var name: String
    var email: String
    
    static var permitted = ["name", "email"]
    
    init(node: Node, in context: Context) throws {
        id = node["id"]
        name = try node.extract("name")
        email = try node.extract("email")
    }
    
    func makeNode(context: Context) throws -> Node {
        return .null
    }
    
    static func prepare(_ database: Database) throws {}
    static func revert(_ database: Database) throws {}
}

extension TestModel {
    static func updateThrownError(_ error: Error) -> AbortError {
        return Abort.custom(status: .badRequest, message: "Username not provided.")
    }
}

extension Abort: Equatable {
    static public func ==(lhs: Abort, rhs: Abort) -> Bool {
        return lhs.code == rhs.code && lhs.message == rhs.message
    }
}
