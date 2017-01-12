import Vapor

/// A request-extractable `Model`.
public protocol Sanitizable {
    /// Fields that are permitted to be deserialized from a Request's JSON.
    static var permitted: [String] { get }
    
    /// Override the error thrown when a `Model` fails to initialize.
    static func updateThrownError(_ error: Error) -> AbortError
}

extension Sanitizable {
    public static func updateThrownError(_ error: Error) -> AbortError {
        return Abort.badRequest
    }
}
