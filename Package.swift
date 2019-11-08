// swift-tools-version:5.1
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "RTRootNavigationController_swift",
    platforms: [.iOS(.v10)],
    products: [
        .library(
            name: "RTRootNavigationController_swift",
            targets: ["RTRootNavigationController_swift"]),
    ],

    targets: [
        .target(
            name: "RTRootNavigationController_swift",
            path: "Source")],
    swiftLanguageVersions: [.v4_2]
)
