// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "MiniSDK-iOS",
    platforms: [
        .iOS(.v13)
    ],
    products: [
        .library(
            name: "MiniSDK",
            targets: ["MiniSDK"]
        ),
    ],
    dependencies: [
        .package(
            url: "https://github.com/firebase/firebase-ios-sdk.git",
            from: "10.0.0"
        )
    ],
    targets: [
        .target(
            name: "MiniSDK",
            dependencies: [
                .product(name: "FirebaseMessaging", package: "firebase-ios-sdk")
            ],
            path: "MiniSDK-iOS"
        ),
        .testTarget(
            name: "MiniSDKTests",
            dependencies: ["MiniSDK"],
            path: "Tests"
        ),
    ]
)