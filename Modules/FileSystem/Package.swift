// swift-tools-version: 6.1
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "FileSystem",
    platforms: [.macOS(.v13)],
    products: [
        .library(name: "FileSystem", targets: ["FileSystem"]),
    ],
    targets: [
        .target(name: "FileSystem"),
        .testTarget(name: "FileSystemTests", dependencies: ["FileSystem"]),
    ]
)
