import HTTP
import Vapor

extension Request {
    /// Extracts a `Model` from the Request's JSON, first stripping sensitive fields.
    ///
    /// - Throws:
    ///     - badRequest: Thrown when the request doesn't have a JSON body.
    ///     - updateErrorThrown: `Sanitizable` models have the ability to override
    ///         the error thrown for when a model fails to instantiate.
    /// 
    /// - Returns: The extracted, sanitized `Model`.
    public func extractModel<M: Model>() throws -> M where M: Sanitizable {
        guard let json = self.json else {
            throw Abort.badRequest
        }
        
        let sanitized = json.permit(M.permitted)
        
        try M.preValidate(data: sanitized)
        
        let model: M
        do {
            model = try M(node: sanitized)
        } catch {
            let error = M.updateThrownError(error)
            throw error
        }
        
        try model.postValidate()
        return model
    }
}
