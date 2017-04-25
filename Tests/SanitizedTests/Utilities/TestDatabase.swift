import Vapor
import Fluent

class TestDriver: Driver {
    var idKey: String = "id"
    var idType: IdentifierType = .custom("some-type")
    var keyNamingConvention: KeyNamingConvention = .camelCase
    var queryLogger: QueryLogger? = nil
    func makeConnection(_ type: ConnectionType) throws -> Connection {
        return TestConnection()
    }
    
    func schema(_ schema: Schema) throws {}
    
    @discardableResult
    public func raw(_ query: String, _ values: [Node] = []) throws -> Node {
        return .null
    }
}

class TestConnection: Connection {
    var queryLogger: QueryLogger?
    var isClosed: Bool = false

    public func query<E: Entity>(_ query: RawOr<Query<E>>) throws -> Node {
        switch query.wrapped!.action {
        case .fetch:
            return Node.array([Node.object([
                "id": 1,
                "name": "Jimmy",
                "email": "jimmy_jim@tested.com"
            ])])
        default:
            return nil
        }
    }
}
