# sanitized
[![Language](https://img.shields.io/badge/Swift-3-brightgreen.svg)](http://swift.org)
[![Build Status](https://travis-ci.org/nodes-vapor/sanitized.svg?branch=master)](https://travis-ci.org/nodes-vapor/sanitized)
[![codecov](https://codecov.io/gh/nodes-vapor/sanitized/branch/master/graph/badge.svg)](https://codecov.io/gh/nodes-vapor/sanitized)
[![GitHub license](https://img.shields.io/badge/license-MIT-blue.svg)](https://raw.githubusercontent.com/nodes-vapor/sanitized/master/LICENSE)

Safely extract Vapor models from requests.

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

## 🏆 Credits
This package is developed and maintained by the Vapor team at [Nodes](https://www.nodes.dk).

## 📄 License
This package is open-sourced software licensed under the [MIT license](http://opensource.org/licenses/MIT)