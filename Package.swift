import PackageDescription

let package = Package(
    name: "Sanitized",
    dependencies: [
        .Package(url: "https://github.com/vapor/vapor", majorVersion: 1),
    ]
)
