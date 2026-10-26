// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "RTRootNavigationController_Swift",
    platforms: [.iOS(.v13)],
    products: [.library(name: "RTRootNavigationController_Swift", targets: ["RTRootNavigationController_Swift"])],
    targets: [
        .target(name: "RTRootNavigationController_Swift"),
        .testTarget(name: "RTRootNavigationControllerTests", dependencies: ["RTRootNavigationController_Swift"])
    ]
)
