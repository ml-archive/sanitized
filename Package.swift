import PackageDescription

let package = Package(
    name: "Sanitized",
    dependencies: [
        .Package(url: "https://github.com/vapor/vapor.git", majorVersion: 1),
    ]
)
