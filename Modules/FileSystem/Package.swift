// swift-tools-version: 6.1
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "FileSystem",
    platforms: [.macOS(.v13)],
    products: [
        .library(name: "FileSystem", targets: ["FileSystem"]),
    ],
    dependencies: [
        .package(url: "https://github.com/Kamaalio/KamaalSwift.git", "2.3.1"..<"3.0.0"),
    ],
    targets: [
        .target(name: "FileSystem", dependencies: [
            .product(name: "KamaalExtensions", package: "KamaalSwift"),
        ]),
        .testTarget(name: "FileSystemTests", dependencies: ["FileSystem"]),
    ]
)
