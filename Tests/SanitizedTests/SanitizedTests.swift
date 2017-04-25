import XCTest
import HTTP
import Vapor
import FluentProvider

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
            XCTAssertEqual(model.id, 1337)
            XCTAssertEqual(model.name, "Brett")
            XCTAssertEqual(model.email, "test@tested.com")
        }
    }


    // MARK: - Validation.

    func testPreValidateError() {
        let request = buildRequest(body: [
            "email": "test@tested.com"
        ])
        
        expect(toThrow: Abort(
            .badRequest,
            metadata: nil,
            reason: "No name provided."
        )) {
            let _: TestModel = try request.extractModel()
        }
    }
    
    func testPostValidateError() {
        let request = buildRequest(body: [
            "id": 1,
            "name": "Brett",
            "email": "t@t.com"
        ])
        
        let expectedError = Abort(
            .badRequest,
            metadata: nil,
            reason: "Email must be longer than 8 characters."
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
        let model = try! TestModel(json: JSON([
            "id": 15,
            "name": "Rylo Ken",
            "email": "test@tested.com"
        ]))
        
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
        let model = try! TestModel(json: JSON([
            "id": 15,
            "name": "Rylo Ken",
            "email": "test@tested.com"
        ]))
        
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

class TestModel: Model, Sanitizable {
    var id: Node?
    var name: String
    var email: String
    var storage: Storage

    static var permitted = ["name", "email"]

    required init(json: JSON) throws {
        id = try json.get("id")
        name = try json.get("name")
        email = try json.get("email")
        storage = Storage()
    }

    public func makeJSON() -> JSON {
        return try! JSON (node: [
                "id": id as Any,
                "name": name,
                "email": email
            ])
    }

    func makeRow() throws -> Row {
        return Row()
    }

    required init(row: Row) throws {
        id = try row.get("id")
        name = try row.get("name")
        email = try row.get("email")
        storage = Storage()
    }
    
    static func prepare(_ database: Database) throws {}
    static func revert(_ database: Database) throws {}
}

extension TestModel {
    static func updateThrownError(_ error: Error) -> AbortError {
        return Abort(
            .badRequest,
            metadata: nil,
            reason: "Username not provided.")
    }
    
    static func preValidate(data: JSON) throws {
        guard data["name"]?.string != nil else {
            throw Abort(
                .badRequest,
                metadata: nil,
                reason: "No name provided."
            )
        }
        
        guard data["email"]?.string != nil else {
            throw Abort(
                .badRequest,
                metadata: nil,
                reason: "No email provided."
            )
        }
    }
    
    func postValidate() throws {
        guard email.characters.count > 8 else {
            throw Abort(
                .badRequest,
                metadata: nil,
                reason: "Email must be longer than 8 characters."
            )
        }
    }
}

extension Abort: Equatable {
    static public func ==(lhs: Abort, rhs: Abort) -> Bool {
        return lhs.identifier == rhs.identifier && lhs.reason == rhs.reason
    }
}
