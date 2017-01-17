import HTTP
import Node
import Vapor

extension Request {
    /// Extracts a `Model` from the Request's JSON, first stripping sensitive fields.
    ///
    /// - Throws:
    ///     - badRequest: Thrown when the request doesn't have a JSON body.
    ///     - updateErrorThrown: `Sanitizable` models have the ability to override
    ///         the error thrown when a model fails to instantiate.
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
    
    /// Updates the `Model` with the provided `id`, first stripping sensitive fields
    ///
    /// - Parameters:
    ///     - id: id of the `Model` to fetch and then patch
    ///
    /// - Throws:
    ///     - notFound: No entity found with the provided `id`.
    ///     - badRequest: Thrown when the request doesn't have a JSON body.
    ///     - updateErrorThrown: `Sanitizable` models have the ability to override
    ///         the error thrown when a model fails to instantiate.
    ///
    /// - Returns: The updated `Model`.
    public func patchModel<M: Model>(id: NodeRepresentable) throws -> M where M: Sanitizable {
        guard let model = try M.find(id) else {
            throw Abort.notFound
        }
        
        return try patchModel(model)
    }
    
    /// Updates the provided `Model`, first stripping sensitive fields
    ///
    /// - Parameters:
    ///     - model: the `Model` to patch
    ///
    /// - Throws:
    ///     - badRequest: Thrown when the request doesn't have a JSON body.
    ///     - updateErrorThrown: `Sanitizable` models have the ability to override
    ///         the error thrown when a model fails to instantiate.
    ///
    /// - Returns: The updated `Model`.
    public func patchModel<M: Model>(_ model: M) throws -> M where M: Sanitizable {
        guard let requestJSON = self.json?.permit(M.permitted).makeNode().nodeObject else {
            throw Abort.badRequest
        }
        
        var modelJSON = try model.makeNode()
        
        requestJSON.forEach {
            modelJSON[$0.key] = $0.value
        }
        
        var model: M
        do {
            model = try M(node: modelJSON)
        } catch {
            let error = M.updateThrownError(error)
            throw error
        }
        
        model.exists = true
        try model.postValidate()
        return model
    }
}
