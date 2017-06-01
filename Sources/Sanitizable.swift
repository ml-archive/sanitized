import Vapor

/// A request-extractable `Model`.
public protocol Sanitizable: JSONInitializable, JSONRepresentable {
    /// Fields that are permitted to be deserialized from a Request's JSON.
    static var permitted: [String] { get }
    
    /// Override the error thrown when a `Model` fails to initialize.
    static func updateThrownError(_ error: Error) -> AbortError
    
    /// Validate the Request's JSON before constructing a Model.
    /// Useful for checking if fields exist.
    static func preValidate(data: JSON) throws
    
    /// Validate all deserialized fields.
    func postValidate() throws
}

extension Sanitizable {
    public static func updateThrownError(_ error: Error) -> AbortError {
        return Abort.badRequest
    }
    
    public static func preValidate(data: JSON) throws {
        
    }
    
    public func postValidate() throws {
        
    }
}

public enum CredentialScope {
    case none
    case user
    case otherUser
    case admin
}

extension CredentialScope: Context {
    
}
