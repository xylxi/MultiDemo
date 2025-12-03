// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "ViewPagerKit",
    platforms: [
        .iOS(.v13)
    ],
    products: [
        .library(
            name: "ViewPagerKit",
            targets: ["ViewPagerKit"]),
    ],
    dependencies: [
        .package(url: "https://github.com/SnapKit/SnapKit.git", from: "5.6.0")
    ],
    targets: [
        .target(
            name: "ViewPagerKit",
            dependencies: ["SnapKit"]),
    ]
)

