// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "AssaultCubeData",
    platforms: [.iOS(.v15), .macOS(.v13)],
    products: [.library(name: "AssaultCubeData", targets: ["AssaultCubeData"])],
    dependencies: [
        .package(url: "https://github.com/weichsel/ZIPFoundation.git", from: "0.9.19")
    ],
    targets: [
        .target(
            name: "AssaultCubeData",
            dependencies: [.product(name: "ZIPFoundation", package: "ZIPFoundation")]
        ),
        .testTarget(name: "AssaultCubeDataTests", dependencies: ["AssaultCubeData"])
    ]
)
