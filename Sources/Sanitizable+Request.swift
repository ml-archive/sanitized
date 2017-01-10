import HTTP
import Vapor

extension Request {
    public func extractModel<M: Model>() throws -> M where M: Sanitizable {
        guard let json = self.json else {
            throw Abort.badRequest
        }
        
        let sanitized = json.permit(M.permitted)
        
        return try M(node: sanitized)
    }
}
