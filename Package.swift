// swift-tools-version: 5.10
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "iOSFirebaseDataParser",
    dependencies: [
        .package(url: "https://github.com/apple/example-package-figlet", branch: "main"),
        .package(url: "https://github.com/apple/swift-argument-parser", from: "1.0.0"),
        .package(url: "https://github.com/yaslab/CSV.swift", .upToNextMajor(from: "2.4.3")),
        .package(url: "https://github.com/scottrhoyt/SwiftyTextTable.git", from: "0.5.0")
    ],
    targets: [
        // Main executable target
        .executableTarget(
            name: "iOSFirebaseDataParser",
            dependencies: [
                .product(name: "Figlet", package: "example-package-figlet"),
                .product(name: "ArgumentParser", package: "swift-argument-parser"),
                .product(name: "CSV", package: "CSV.swift"),
                .product(name: "SwiftyTextTable", package: "SwiftyTextTable")
            ],
            path: "Sources"
        ),
        
        // Add test target
        .testTarget(
            name: "iOSFirebaseDataParserTests",
            dependencies: [
                "iOSFirebaseDataParser", // The main executable target for testing
                .product(name: "CSV", package: "CSV.swift"),
                .product(name: "SwiftyTextTable", package: "SwiftyTextTable")
            ],
            path: "Tests"
        ),
    ]
)
