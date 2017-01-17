import Vapor
import Fluent

class TestDriver: Driver {
    var idKey: String = "id"
    
    func query<T : Entity>(_ query: Query<T>) throws -> Node {
        switch query.action {
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
    
    func schema(_ schema: Schema) throws {}
    
    @discardableResult
    public func raw(_ query: String, _ values: [Node] = []) throws -> Node {
        return .null
    }
}
