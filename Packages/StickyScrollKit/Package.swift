// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "StickyScrollKit",
    platforms: [
        .iOS(.v13)
    ],
    products: [
        .library(
            name: "StickyScrollKit",
            targets: ["StickyScrollKit"]
        ),
    ],
    dependencies: [
        .package(url: "https://github.com/SnapKit/SnapKit.git", from: "5.0.0")
    ],
    targets: [
        .target(
            name: "StickyScrollKit",
            dependencies: ["SnapKit"],
            path: "Sources/StickyScrollKit"
        ),
    ]
)

