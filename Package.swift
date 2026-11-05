// swift-tools-version: 5.9
// Purpose: Build Clippit and run storage checks without requiring Xcode.
import PackageDescription

let package = Package(
    name: "Clippit",
    platforms: [.macOS(.v14)],
    dependencies: [
        .package(url: "https://github.com/stephencelis/SQLite.swift.git", exact: "0.15.3"),
        .package(url: "https://github.com/soffes/HotKey.git", exact: "0.2.1")
    ],
    targets: [
        .executableTarget(name: "Clippit", dependencies: [.product(name: "SQLite", package: "SQLite.swift"), .product(name: "HotKey", package: "HotKey")], path: "Clippit", exclude: ["Assets.xcassets"], resources: [.copy("ThirdPartyNotices.txt")]),
        .testTarget(name: "ClippitTests", dependencies: ["Clippit"], path: "Tests")
    ]
)
