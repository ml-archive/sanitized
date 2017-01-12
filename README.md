# Sanitized
[![Language](https://img.shields.io/badge/Swift-3-brightgreen.svg)](http://swift.org)
[![Build Status](https://travis-ci.org/nodes-vapor/sanitized.svg?branch=master)](https://travis-ci.org/nodes-vapor/sanitized)
[![codecov](https://codecov.io/gh/nodes-vapor/sanitized/branch/master/graph/badge.svg)](https://codecov.io/gh/nodes-vapor/sanitized)
[![GitHub license](https://img.shields.io/badge/license-MIT-blue.svg)](https://raw.githubusercontent.com/nodes-vapor/sanitized/master/LICENSE)

Safely extract and validate Vapor models from requests.

## Integration
Update your `Package.swift` file.
```swift
.Package(url: "https://github.com/nodes-vapor/sanitized.git", majorVersion: 0)
```

## Getting started 🚀
Before you're able to extract your model from a request it needs to conform to the protocol `Sanitizable`. To be conferment all you need to do is add a `[String]` named `permitted` with a list of keys you wish to allow.

### User.swift
```swift
struct User: Model, Sanitizable {
    var id: Node?
    var name: String
    var email: String
    
    // will only allow the keys `name` and `email`
    static var permitted = ["name", "email"]
    
    init(node: Node, in context: Context) throws {
        id = node["id"]
        name = try node.extract("name")
        email = try node.extract("email")
    }
    
    //...
}
```

Now that you have a conforming model, you can safely extract it from a `Request`.

### Request body
```json
{
  "id": 10,
  "name": "Brett",
  "email": "test@tested.com"
}
```

### Main.swift
```swift
drop.post("users") { req in 
    var user: User = try request.extractModel()
    print(user.id == nil) // prints `true`
    try user.save()
    return user
}
```

## Validation 👌
This package doesn't specifically provide any validation tools, but it is capable of running your validation suite for you. Thusly, simplifying the logic in your controllers. Sanitized has two ways of accomplishing this: pre and post validation.

### Pre-init validation
This type of validation is ran before the model is initialized and is checked against the request's JSON. This type of field is useful for when you only want to check if a field exists before continuing.

Create a `preValidation` check by overriding the default implementation in your `Sanitizable` model.
```swift
static func preValidate(data: JSON) throws {
    // we only want to ensure that `name` exists/
    guard data["name"]?.string != nil else {
      throw MyError.invalidRequest("Name not provided.")
    }
}
``` 

### Post-init validation
This type of validation is ran after the model has been initialized is useful for checking the content of fields while using Swift-native types.

Create a `postValidation` check by overriding the default implementation in your `Sanitizable` model.
```swift
func postValidate() throws {
    guard email.count > 8 else {
        throw Abort.custom(
            status: .badRequest,
            message: "Email must be longer than 8 characters."
        )
    }
}
```

## Overriding error thrown on failed `init` 🔨
The error thrown by a failed `Node.extract` will be turned into a `505 Internal Server Error` if not caught and changed before being caught by Vapor's AbortMiddleware. By default, this package will catch that error and convert it into a `400 Bad Request`. If you wish to disable this for development environments or throw your own error, you can override the following default implementation:
```swift
static func updateThrownError(_ error: Error) -> AbortError {
    // recreates the default behavior of `AbortMiddleware`.
    return Abort.custom(
        status: .internalServerError,
        message: "\(error)"
    )
}
```

## 🏆 Credits
This package is developed and maintained by the Vapor team at [Nodes](https://www.nodes.dk).

## 📄 License
This package is open-sourced software licensed under the [MIT license](http://opensource.org/licenses/MIT)