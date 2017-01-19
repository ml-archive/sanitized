import XCTest
import HTTP
import Vapor

@testable import Sanitized

class SanitizedTests: XCTestCase {
    static var allTests = [
        ("testBasic", testBasic),
        ("testBasicFailed", testBasicFailed),
        ("testPreValidateError", testPreValidateError),
        ("testPostValidateError", testPostValidateError),
        ("testPermitted", testPermitted),
        ("testEmptyPermitted", testEmptyPermitted),
    ]


    // MARK: - Extraction.

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


    // MARK: - Injection.

    func testInjectingNewKeys() {
        let request = buildRequest(body: [
            "id": 1,
            "name": "Brett"
        ])
        
        expectNoThrow() {
            let model: TestModel = try request.extractModel(
                injecting: ["email": "test@tested.com"]
            )
            XCTAssertNil(model.id)
            XCTAssertEqual(model.name, "Brett")
            XCTAssertEqual(model.email, "test@tested.com")
        }
    }

    func testOverridingKeys() {
        let request = buildRequest(body: [
            "id": 1,
            "name": "Brett",
            "email": "test@tested.com"
        ])
        
        expectNoThrow() {
            let model: TestModel = try request.extractModel(
                injecting: ["email": "test@doubletested.com"]
            )
            XCTAssertNil(model.id)
            XCTAssertEqual(model.name, "Brett")
            XCTAssertEqual(model.email, "test@doubletested.com")
        }
    }

    func testInjectingSanitizedKeys() {
        let request = buildRequest(body: [
            "id": 1,
            "name": "Brett",
            "email": "test@tested.com"
        ])
        
        expectNoThrow() {
            let model: TestModel = try request.extractModel(
                injecting: ["id": 1337]
            )
            XCTAssertNil(model.id)
            XCTAssertEqual(model.name, "Brett")
            XCTAssertEqual(model.email, "test@tested.com")
        }
    }


    // MARK: - Validation.

    func testPreValidateError() {
        let request = buildRequest(body: [
            "email": "test@tested.com"
        ])
        
        expect(toThrow: Abort.custom(status: .badRequest, message: "No name provided.")) {
            let _: TestModel = try request.extractModel()
        }
    }
    
    func testPostValidateError() {
        let request = buildRequest(body: [
            "id": 1,
            "name": "Brett",
            "email": "t@t.com"
        ])
        
        let expectedError = Abort.custom(
            status: .badRequest,
            message: "Email must be longer than 8 characters."
        )
        
        expect(toThrow: expectedError) {
            let _: TestModel = try request.extractModel()
        }
    }


    // MARK: - Permitted fields.

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


    // MARK: - Patching.

    func testPatchBasic() {
        let model = try! TestModel(node: [
            "id": 15,
            "name": "Rylo Ken",
            "email": "test@tested.com"
        ])
        
        let request = buildRequest(body: [
            "id": 11, // this should be sanitized
            "email": "rylo_ken@tested.com"
        ])
        
        expectNoThrow() {
            let model = try request.patchModel(model)
            XCTAssertEqual(model.id?.int, 15)
            XCTAssertEqual(model.name, "Rylo Ken")
            XCTAssertEqual(model.email, "rylo_ken@tested.com")
        }
    }
    
    func testPatchFailed() {
        let model = try! TestModel(node: [
            "id": 15,
            "name": "Rylo Ken",
            "email": "test@tested.com"
        ])
        
        let request = buildInvalidRequest()
        
        expect(toThrow: Abort.badRequest) {
            let _: TestModel = try request.patchModel(model)
        }
    }
    
    func testPatchById() {
        Database.default = Database(TestDriver())
        let request = buildRequest(body: [
            "id": 11, // this should be sanitized
            "email": "jimmy_jim@tested.com"
        ])
        
        expectNoThrow() {
            let model: TestModel = try request.patchModel(id: 1)
            XCTAssertEqual(model.id?.int, 1, "Id shouldn't have changed")
            XCTAssertEqual(model.name, "Jimmy", "Name shouldn't have changed")
            XCTAssertEqual(model.email, "jimmy_jim@tested.com", "email should've changed")
        }
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
        return try Node(node: [
            "id": id,
            "name": name,
            "email": "email"
        ])
    }
    
    static func prepare(_ database: Database) throws {}
    static func revert(_ database: Database) throws {}
}

extension TestModel {
    static func updateThrownError(_ error: Error) -> AbortError {
        return Abort.custom(status: .badRequest, message: "Username not provided.")
    }
    
    static func preValidate(data: JSON) throws {
        guard data["name"]?.string != nil else {
            throw Abort.custom(status: .badRequest, message: "No name provided.")
        }
        
        guard data["email"]?.string != nil else {
            throw Abort.custom(status: .badRequest, message: "No email provided.")
        }
    }
    
    func postValidate() throws {
        guard email.count > 8 else {
            throw Abort.custom(
                status: .badRequest,
                message: "Email must be longer than 8 characters."
            )
        }
    }
}

extension Abort: Equatable {
    static public func ==(lhs: Abort, rhs: Abort) -> Bool {
        return lhs.code == rhs.code && lhs.message == rhs.message
    }
}
