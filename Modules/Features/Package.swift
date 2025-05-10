// swift-tools-version: 6.1
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "Features",
    defaultLocalization: "en",
    platforms: [.macOS(.v14)],
    products: [
        .library(name: "Transforming", targets: ["Transforming"]),
    ],
    dependencies: [
        .package(url: "https://github.com/Kamaalio/KamaalSwift.git", "2.3.1"..<"3.0.0"),
        .package(path: "../DesignSystem"),
        .package(path: "../FileSystem"),
    ],
    targets: [
        .target(name: "Transforming", dependencies: [
            .product(name: "KamaalExtensions", package: "KamaalSwift"),
            .product(name: "KamaalLogger", package: "KamaalSwift"),
            "DesignSystem",
            "FileSystem",
        ]),
    ]
)
