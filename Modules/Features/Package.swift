// swift-tools-version: 6.1
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "Features",
    platforms: [.macOS(.v13)],
    products: [
        .library(name: "Transforming", targets: ["Transforming"]),
    ],
    targets: [
        .target(name: "Transforming"),
    ]
)
