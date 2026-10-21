// swift-tools-version: 5.9
// Purpose: Build ClipVault and run storage checks without requiring Xcode.
import PackageDescription

let package = Package(
    name: "ClipVault",
    platforms: [.macOS(.v14)],
    dependencies: [
        .package(url: "https://github.com/stephencelis/SQLite.swift.git", exact: "0.15.3"),
        .package(url: "https://github.com/soffes/HotKey.git", exact: "0.2.1")
    ],
    targets: [
        .executableTarget(name: "ClipVault", dependencies: [.product(name: "SQLite", package: "SQLite.swift"), .product(name: "HotKey", package: "HotKey")], path: "ClipVault", exclude: ["Assets.xcassets"], resources: [.copy("ThirdPartyNotices.txt")]),
        .testTarget(name: "ClipVaultTests", dependencies: ["ClipVault"], path: "Tests")
    ]
)
